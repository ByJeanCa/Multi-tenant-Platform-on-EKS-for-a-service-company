import os
from celery import Celery

def make_celery() -> Celery:
    broker = os.getenv("CELERY_BROKER_URL", os.getenv("REDIS_URL", "redis://redis:6379/0"))
    backend = os.getenv("CELERY_RESULT_BACKEND", broker)

    celery_app = Celery("myapp", broker=broker, backend=backend)

    # Resiliencia básica
    celery_app.conf.update(
        task_track_started=True,
        broker_connection_retry=True,
        broker_connection_retry_on_startup=True,
        broker_connection_max_retries=None,  # retry infinito con backoff del worker/infra
        result_expires=3600,
    )
    return celery_app

celery_app = make_celery()