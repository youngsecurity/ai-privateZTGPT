#FROM python:3.11.6-slim-bookworm as base
FROM --platform=linux/amd64 cgr.dev/chainguard/python:latest-dev AS base

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt --user

FROM cgr.dev/chainguard/python:latest

WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

# Install poetry
RUN pip install pipx
RUN python3 -m pipx ensurepath
RUN pipx install poetry
ENV PATH="/root/.local/bin:$PATH"
ENV PATH=".venv/bin/:$PATH"

# https://python-poetry.org/docs/configuration/#virtualenvsin-project
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

FROM base as dependencies
WORKDIR /home/worker/app
COPY pyproject.toml poetry.lock ./

RUN poetry install --extras "ui llms-ollama embeddings-ollama vector-stores-qdrant"

FROM base as app

ENV PYTHONUNBUFFERED=1
ENV PORT=8080
EXPOSE 8080

# Prepare a non-root user
RUN adduser --system worker
WORKDIR /home/worker/app

RUN mkdir local_data; chown worker local_data
RUN mkdir models; chown worker models
COPY --chown=worker --from=dependencies /home/worker/app/.venv/ .venv
COPY --chown=worker private_gpt/ private_gpt
COPY --chown=worker fern/ fern
COPY --chown=worker *.yaml *.md ./
COPY --chown=worker scripts/ scripts

ENV PYTHONPATH="$PYTHONPATH:/private_gpt/"

USER worker
ENTRYPOINT python -m private_gpt