
import time
from flask import g, request, Response
from sqlalchemy import text
from prometheus_client import (
    Counter,
    Histogram,
    generate_latest,
    CONTENT_TYPE_LATEST,
)
from .db import db

REQUESTS = Counter(
    "todolist_http_requests_total",
    "Number of HTTP requests",
    ["method", "route", "status"],
)

LATENCY = Histogram(
    "todolist_request_duration_seconds",
    "HTTP request duration in seconds",
    ["route"],
)


def install_monitoring(app):

    @app.before_request
    def start_timer():
        g.started_at = time.perf_counter()

    @app.after_request
    def record_metrics(response):
        if request.path not in (
            "/metrics",
            "/health/liveness",
            "/health/readiness",
        ):
            route = (
                request.url_rule.rule
                if request.url_rule
                else "unknown"
            )
            REQUESTS.labels(
                request.method,
                route,
                str(response.status_code),
            ).inc()
            LATENCY.labels(route).observe(
                time.perf_counter() - g.started_at
            )
        return response

    @app.get("/health/liveness")
    def liveness():
        return {"status": "alive"}, 200

    @app.get("/health/readiness")
    def readiness():
        try:
            db.session.execute(text("SELECT 1"))
            return {"status": "ready"}, 200
        except Exception:
            app.logger.exception("Readiness check failed")
            return {"status": "not ready"}, 503

    @app.get("/metrics")
    def metrics():
        return Response(
            generate_latest(),
            content_type=CONTENT_TYPE_LATEST,
        )
