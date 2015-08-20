#!/bin/bash

pushd $COGU_HOME >> /dev/null
/jupyter_scripts/j2cli.sh
/jupyter_scripts/setup_git_filters.sh
popd
