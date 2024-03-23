#!/bin/sh
set -e
# run setup to download models
/home/nonroot/app/.venv/bin/python scripts/setup
# shellcheck disable=SC1091
# shellcheck disable=SC3046
source /home/nonroot/app/.venv/bin/activate
# run app
export PGPT_PROFILES=ollama 
make run
#/home/nonroot/app/.venv/bin/python -m private_gpt