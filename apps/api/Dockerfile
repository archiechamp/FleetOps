FROM python:3.12.16-slim-bookworm@sha256:935c3c5b12357a7e10caa9c1e6ca5692344d97cf229832ef584be2cec9fc03df

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /workspace/apps/api

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates gnupg libgssapi-krb5-2 unixodbc \
    && curl -fsSL https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && apt-get update && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18=18.7.1.1-1 \
    && rm -rf /var/lib/apt/lists/* /tmp/packages-microsoft-prod.deb

COPY apps/api/requirements.lock apps/api/pyproject.toml ./
RUN pip install --no-cache-dir --requirement requirements.lock

COPY apps/api/app ./app
COPY apps/api/alembic ./alembic
COPY apps/api/alembic.ini ./alembic.ini
COPY apps/api/tests ./tests
COPY apps/api/tools ./tools
COPY tests/fixtures /workspace/tests/fixtures
COPY database/metadata/model.json /workspace/database/metadata/model.json

RUN useradd --create-home --uid 10001 fleetops && chown -R fleetops:fleetops /workspace
USER fleetops

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
