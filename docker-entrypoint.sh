#!/bin/sh
set -e
# run setup to download models
/home/nonroot/app/.venv/bin/python scripts/setup
# run app
export PGPT_PROFILES=ollama
/home/nonroot/app/.venv/bin/python -m private_gpt