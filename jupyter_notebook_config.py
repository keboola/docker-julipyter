import os
import sys

# Jupyter config http://jupyter-notebook.readthedocs.io/en/latest/config.html
c.NotebookApp.ip = '*'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False
# This changes current working dir, so has to be set to /data/
c.NotebookApp.notebook_dir = '/data/'
# If not set, there is a permission problem with the /data/ directory
c.NotebookApp.allow_root = True
# Disable the Python kernel
c.MultiKernelManager.default_kernel_name = 'julia-1.2'
c.KernelSpecManager.ensure_native_kernel = False

print("Initializing Jupyter.", file=sys.stdout)

# Set a password
if 'PASSWORD' in os.environ and os.environ['PASSWORD']:
    from IPython.lib import passwd
    c.NotebookApp.password = passwd(os.environ['PASSWORD'])
    del os.environ['PASSWORD']
else:
    print('Password must be provided.')
    sys.exit(150)
