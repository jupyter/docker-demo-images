#!/bin/bash
WORK_DIR=${1:-$COGU_HOME}

pushd $WORK_DIR >> /dev/null
j2 Exercises/Sourcing/config/config_tmpl.json > Exercises/Sourcing/config/config.json
j2 Exercises/UI/config_tmpl.yml > Exercises/UI/config.yml
popd
