#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

/usr/local/bin/wait-for-it.sh -t 0 data-loader:80 -- echo "Data loader is up"
#jupyter trust /notebooks/notebook.ipynb
gosu $NB_USER julia /usr/local/bin/install.jl

chgrp -R $NB_GID /data
chown -R $NB_USER /data
chmod -R 0777 /data
# make sure all future files/folders are under groupID 100
chmod -R g+s /data
chmod -R u+s /data
umask 007
# make sure GID 100 has permissions on all future files/folders in the data dir
setfacl -d -m g::rwx /data
echo "directory permissions set"
touch /data/testfile
ls -haltr > /data/testfile

# Handle special flags if we're root
if [ $UID == 0 ] ; then
    # Change UID of NB_USER to NB_UID if it does not match
    if [ "$NB_UID" != $(id -u $NB_USER) ] ; then
        echo "Set user UID to: $NB_UID"
        usermod -u $NB_UID $NB_USER
        # Careful: $HOME might resolve to /root depending on how the
        # container is started. Use the $NB_USER home path explicitly.
        for d in "$JULIA_PKGDIR" "/home/$NB_USER"; do
            if [[ ! -z "$d" && -d "$d" ]]; then
                echo "Set ownership to uid $NB_UID: $d"
                chown -R $NB_UID "$d"
            fi
        done
    fi

    # Change GID of NB_USER to NB_GID if NB_GID is passed as a parameter
    if [ "$NB_GID" ] ; then
        echo "Change GID to $NB_GID"
        groupmod -g $NB_GID -o $(id -g -n $NB_USER)
    fi

    # Enable sudo if requested
    if [ ! -z "$GRANT_SUDO" ]; then
        echo "$NB_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook
    fi

    # Exec the command as NB_USER
    echo "Execute the command as $NB_USER"
    exec gosu $NB_USER $*
else
    # Exec the command
    echo "Execute the command"
    exec gosu $NB_USER $*
fi
