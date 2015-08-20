#/bin/bash

# setup_git_filters.sh

# figure out the path to the git repo
# http://stackoverflow.com/questions/18734739/using-ipython-notebooks-under-version-control
# upload ipynb_git_output_filter.py, setup_git_filters.sh, strip_output_notebook.py to 
# https://s3.amazonaws.com/c12e-cognitivecloud/notebook/ipynb_git_output_filter.py etc
wget https://s3.amazonaws.com/c12e-cognitivecloud/notebook/ipynb_git_output_filter.py
wget https://s3.amazonaws.com/c12e-cognitivecloud/notebook/strip_output_notebook.py
git config filter.stripoutput.clean "$(git rev-parse --show-toplevel)/strip_notebook_output.py"
git config filter.stripoutput.smudge cat
git config filter.stripoutput.required true
