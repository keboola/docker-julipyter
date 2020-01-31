import os
import sys
import io
import requests

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

def saveFile(file_path, token):
    """
    Construct a requests POST call with args and kwargs and process the
    results.
    Args:
        file_path: The relative path to the file from the datadir, including filename and extension
        token: keboola storage api token
    Returns:
        body: Response body parsed from json.
    Raises:
        requests.HTTPError: If the API request fails.
    """

    url = 'http://data-loader-api/data-loader-api/save'
    headers = {'X-StorageApi-Token': token, 'User-Agent': 'Keboola Sandbox Autosave Request'}
    payload = {'file':{'source': file_path, 'tags': ['autosave']}}

    # the timeout is set to > 3min because of the delay on 400 level exception responses
    # https://keboola.atlassian.net/browse/PS-186
    r = requests.post(url, json=payload, headers=headers, timeout=240)
    try:
        r.raise_for_status()
    except requests.HTTPError:
        # Handle different error codes
        raise
    else:
        return r.json()

def script_post_save(model, os_path, contents_manager, **kwargs):
    """
    saves the ipynb file to keboola storage on every save within the notebook
    """
    if model['type'] != 'notebook':
        return
    log = contents_manager.log

    # get the token from env
    token = None
    if 'KBC_TOKEN' in os.environ:
        token = os.environ['KBC_TOKEN']
    else:
        log.error('Could not find the Keboola Storage API token.')
        raise Exception('Could not find the Keboola Storage API token.')
    try:
        response = saveFile(os.path.relpath(os_path), token)
    except requests.HTTPError:
        log.error('Error saving notebook:' + response.json())
        raise

    log.info("Successfully saved the notebook to Keboola Connection")

c.FileContentsManager.post_save_hook = script_post_save
