FROM --platform=linux/amd64 cgr.dev/chainguard/python:latest-dev as base

LABEL maintainer="Joseph Young <joe@youngsecurity.net>"
LABEL description="Docker container for Private Zero Trust GPT - a production-ready AI project that allows you to ask questions about your cybersecurity and organization corpus using the power of Large Language Models (LLMs)."

ENV PATH="/home/nonroot/.local/bin:$PATH"
ENV PATH=".venv/bin/:$PATH"
RUN pip install --no-cache-dir --user pipx
RUN python3 -m pipx ensurepath
RUN pipx install poetry

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

USER nonroot
WORKDIR /home/nonroot/app

# Copy from dependencies
RUN mkdir local_data && chown nonroot local_data; mkdir models && chown nonroot models
COPY --chown=nonroot --from=dependencies /home/nonroot/app/.venv/ .venv
COPY --chown=nonroot private_gpt/ private_gpt fern/ fern *.yaml *.md ./ scripts/

ENV PYTHONPATH="$PYTHONPATH:/private_gpt/"

USER nonroot
ENTRYPOINT ["/bin/sh" "-c" "export PGPT_PROFILES=ollama && python -m private_gpt"]