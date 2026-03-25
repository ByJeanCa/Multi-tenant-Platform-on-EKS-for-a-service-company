import logging
import sys
from pythonjsonlogger import jsonlogger

def configure_logging(level: str = "INFO") -> None:
    logger = logging.getLogger()
    logger.setLevel(level.upper())

    handler = logging.StreamHandler(sys.stdout)
    formatter = jsonlogger.JsonFormatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s %(job_id)s %(duration_ms)s %(result)s"
    )
    handler.setFormatter(formatter)

    logger.handlers = [handler]