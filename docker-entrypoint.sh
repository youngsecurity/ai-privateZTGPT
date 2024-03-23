#!/bin/sh
set -e
# run setup to download models
/home/nonroot/app/.venv/bin/python scripts/setup
# run app
export PGPT_PROFILES=ollama make run
#/home/nonroot/app/.venv/bin/python -m private_gpt