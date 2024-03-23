#!/bin/sh
set -e
# run setup to download models
/home/nonroot/app/.venv/bin/python scripts/setup
# run app
/home/nonroot/app/.venv/bin/python -m -private_gpt