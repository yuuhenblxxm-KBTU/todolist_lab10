FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir \
    -r requirements.txt gunicorn==23.0.0

RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup \
    -d /app -s /usr/sbin/nologin appuser && \
    mkdir -p /app/instance && \
    chown -R 10001:10001 /app/instance

COPY app ./app
COPY run.py .

USER 10001:10001

EXPOSE 8000

CMD ["gunicorn", "--workers", "1", \
     "--threads", "2", \
     "--bind", "0.0.0.0:8000", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "run:app"]
