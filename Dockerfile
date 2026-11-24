FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt "gunicorn>=23,<26"

RUN groupadd --gid 10001 appgroup && \
    useradd --uid 10001 --gid 10001 \
    --home-dir /app --no-create-home \
    --shell /usr/sbin/nologin appuser

COPY app ./app
COPY run.py .

RUN mkdir -p /app/instance && \
    chown -R 10001:10001 /app

USER 10001:10001

EXPOSE 8000

CMD ["sh", "-c", "test -n \"$KEY\" || { echo 'KEY is missing'; exit 1; }; exec gunicorn --workers 1 --threads 2 --bind 0.0.0.0:8000 --worker-tmp-dir /tmp --access-logfile - --error-logfile - run:app"]