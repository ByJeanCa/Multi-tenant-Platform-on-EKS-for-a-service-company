import logging
import os
import random
import time
from celery import Celery
from app.logging_config import configure_logging

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
configure_logging(LOG_LEVEL)
log = logging.getLogger("worker")

broker = os.getenv("CELERY_BROKER_URL", os.getenv("REDIS_URL", "redis://redis:6379/0"))
backend = os.getenv("CELERY_RESULT_BACKEND", broker)

celery_app = Celery("myapp-worker", broker=broker, backend=backend)
celery_app.conf.update(
    task_track_started=True,
    broker_connection_retry=True,
    broker_connection_retry_on_startup=True,
    broker_connection_max_retries=None,
    result_expires=3600,
)

@celery_app.task(name="jobs.process", bind=True)
def process_job(self, email: str, payload: str):
    job_id = self.request.id
    start = time.time()

    # Simula trabajo 2-5s
    sleep_s = random.uniform(2, 5)
    time.sleep(sleep_s)

    duration_ms = int((time.time() - start) * 1000)

    log.info(
        "job_done",
        extra={
            "job_id": job_id,
            "duration_ms": duration_ms,
            "result": "success",
        },
    )

    # Lo que devuelvas queda en backend (Redis)
    return {"email": email, "payload_len": len(payload), "duration_ms": duration_ms}