FROM --platform=linux/amd64 cgr.dev/chainguard/python:latest-dev as base

LABEL maintainer="Joseph Young <joe@youngsecurity.net>"
LABEL description="Docker container for privateGPT - a production-ready AI project that allows you to ask questions about your documents using the power of Large Language Models (LLMs)."

# Install poetry
ENV PATH="/home/nonroot/.local/bin:$PATH"
ENV PATH=".venv/bin/:$PATH"
RUN pip install poetry --no-cache-dir --user

# https://python-poetry.org/docs/configuration/#virtualenvsin-project
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

FROM base as dependencies

WORKDIR /home/nonroot/app
COPY pyproject.toml poetry.lock ./
RUN poetry run pip install doc2text docx2txt EbookLib html2text python-pptx Pillow --no-cache-dir && \
    poetry install --no-cache --extras "ui llms-ollama embeddings-ollama embeddings-huggingface vector-stores-qdrant"

FROM base as app

ENV MPLCONFIGDIR="/home/nonroot/app/models/.config/matplotlib" \
    HF_HOME="/home/nonroot/app/models/cache" \
    PYTHONUNBUFFERED=1 \
    PORT=8080
EXPOSE 8080

# Prepare a non-root user "nonroot"
USER nonroot
WORKDIR /home/nonroot/app

# Copy from dependencies
RUN mkdir local_data && chown nonroot local_data; mkdir models && chown nonroot models
COPY --chown=worker --from=dependencies /home/nonroot/app/.venv/ .venv
COPY --chown=nonroot private_gpt/ private_gpt
COPY --chown=nonroot fern/ fern
COPY --chown=nonroot *.yaml *.md ./
COPY --chown=nonroot scripts/ scripts

# Setup environment
ENV PYTHONPATH="$PYTHONPATH:/private_gpt/"

VOLUME /home/nonroot/app/local_data
VOLUME /home/nonroot/app/models

# Setup entrypoint
#COPY docker-entrypoint.sh /
#ENTRYPOINT ["bash", "/docker-entrypoint.sh"]
ENTRYPOINT export PGPT_PROFILES=ollama && python -m private_gpt