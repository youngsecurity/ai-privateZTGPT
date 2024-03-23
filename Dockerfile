#FROM python:3.11.6-slim-bookworm as base
FROM --platform=linux/amd64 cgr.dev/chainguard/python:latest-dev AS base

# Make sure you update Python version in path
COPY --from=base /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

# Install poetry
RUN pip install pipx
RUN pipx --version
RUN python3 -m pipx ensurepath
RUN pipx install poetry
ENV PATH="/home/nonroot/.local/bin:$PATH"
ENV PATH=".venv/bin/:$PATH"

# https://python-poetry.org/docs/configuration/#virtualenvsin-project
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

FROM base as dependencies
WORKDIR /home/nonroot/app
COPY pyproject.toml poetry.lock ./

RUN poetry install --extras "ui llms-ollama embeddings-ollama vector-stores-qdrant" && \
    poetry run python scripts/setup && \
    rm -rf \
        .git* \
        .docker* \
        docker* \
        Dockerfile* \
        local_data/.gitignore \
        models/cache/models--* \
        models/embedding/* \
        models/mistral* \
        settings-* \
        tests*

FROM base as app

LABEL maintainer="Joseph Young <joe@youngsecurity.net>"
LABEL description="Docker container for privateGPT - a production-ready AI project that allows you to ask questions about your documents using the power of Large Language Models (LLMs)."

#ARG CMAKE_ARGS='-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR="OpenBLAS" -DLLAMA_AVX=OFF -DLLAMA_AVX2=OFF -DLLAMA_F16C=OFF -DLLAMA_FMA=OFF'
ARG CMAKE_ARGS='-DLLAMA_CUBLAS=ON'

ENV MPLCONFIGDIR="/home/nonroot/app/models/.config/matplotlib" \
    HF_HOME="/home/nonroot/app/models/cache" \
    PYTHONUNBUFFERED=1 \
    PORT=8080
EXPOSE 8080

# Prepare a non-root user
RUN adduser --system nonroot
WORKDIR /home/nonroot/app

RUN mkdir local_data; chown nonroot local_data
RUN mkdir models; chown nonroot models
COPY --chown=nonroot --from=dependencies /home/nonroot/app/.venv/ .venv
COPY --chown=nonroot private_gpt/ private_gpt
COPY --chown=nonroot fern/ fern
COPY --chown=nonroot *.yaml *.md ./
COPY --chown=nonroot scripts/ scripts

ENV PYTHONPATH="$PYTHONPATH:/private_gpt/"

USER nonroot
ENTRYPOINT python -m private_gpt