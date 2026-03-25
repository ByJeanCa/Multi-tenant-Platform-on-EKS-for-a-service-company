import logging
import sys
import uuid
from contextvars import ContextVar
from pythonjsonlogger import jsonlogger

request_id_ctx: ContextVar[str] = ContextVar("request_id", default="-")

def set_request_id(value: str | None) -> str:
    rid = value.strip() if value and value.strip() else str(uuid.uuid4())
    request_id_ctx.set(rid)
    return rid

def configure_logging(level: str = "INFO") -> None:
    logger = logging.getLogger()
    logger.setLevel(level.upper())

    handler = logging.StreamHandler(sys.stdout)
    formatter = jsonlogger.JsonFormatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s %(request_id)s"
    )
    handler.setFormatter(formatter)

    # Custom record factory to inject request_id
    old_factory = logging.getLogRecordFactory()

    def record_factory(*args, **kwargs):
        record = old_factory(*args, **kwargs)
        record.request_id = request_id_ctx.get()
        return record

    logging.setLogRecordFactory(record_factory)

    # Avoid duplicate handlers
    logger.handlers = [handler]