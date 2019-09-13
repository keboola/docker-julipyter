FROM quay.io/keboola/docker-custom-julia:0.2.0

# Taken from https://github.com/jupyter/docker-stacks/blob/master/minimal-notebook/Dockerfile

# Install all OS dependencies for fully functional notebook server
# libav-tools for matplotlib anim
RUN apt-get update && apt-get upgrade -yq python3 \
    && apt-get install -yq --no-install-recommends \
        build-essential \
        emacs \
        git \
        inkscape \
        jed \
        libsm6 \
        libxext-dev \
        libxrender1 \
        lmodern \
        pandoc \
        python-dev \
        python3-pip \
        python3-setuptools \
        texlive-fonts-extra \
        texlive-fonts-recommended \
        texlive-generic-recommended \
        texlive-latex-base \
        texlive-latex-extra \
        texlive-xetex \
        unzip \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Taken from https://github.com/jupyter/docker-stacks/tree/master/base-notebook

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
    echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Configure environment
ENV SHELL /bin/bash
ENV NB_USER root
ENV NB_UID 0
ENV HOME /home/$NB_USER
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Taken from https://github.com/jupyter/docker-stacks/blob/master/scipy-notebook/Dockerfile

# Install Python 3 packages
# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images
RUN pip3 install --no-cache-dir \
    notebook \
    jupyterhub \
    jupyterlab \
    ipywidgets \
    qgrid

# Activate ipywidgets extension in the environment that runs the notebook server
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix \
 && jupyter nbextension enable --py --sys-prefix qgrid

USER root

### Custom stuff 
# Install KBC Transformation package
RUN pip3 install --no-cache-dir --upgrade --force-reinstall git+git://github.com/keboola/python-docker-application.git@2.1.1 \
    && pip3 install --no-cache-dir --upgrade git+git://github.com/keboola/python-transformation.git@1.1.13

### Install Julia Kernel
ENV JUPYTER /usr/local/bin/jupyter
# install packages "globally"
ENV JULIA_DEPOT_PATH /opt/julia-packages/
RUN julia -e 'using Pkg; Pkg.add("IJulia"); Pkg.build("IJulia"); using IJulia' 
# using IJulia is there to precompile the kernel
RUN jupyter kernelspec install /home/root/.local/share/jupyter/kernels/julia-1.2/ \
    && yes | jupyter kernelspec uninstall python3

EXPOSE 8888
WORKDIR /data/

# Configure container startup
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
COPY wait-for-it.sh /usr/local/bin/

RUN chown -R $NB_USER:users /etc/jupyter/
