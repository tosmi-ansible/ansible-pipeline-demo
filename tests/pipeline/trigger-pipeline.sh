#!/bin/bash

set -euf -o pipefail

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

/usr/bin/curl -v el-ansible-staging-ansible-pipeline.apps.ocp.lan.stderr.at -d @"${SCRIPT_DIR}/example-event.json"
