import logging
import os
from fastapi import FastAPI, HTTPException, Request, APIRouter
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from prometheus_fastapi_instrumentator import Instrumentator

from app.logging_config import configure_logging, set_request_id
from app.celery_app import celery_app
from app.healthchecks import check_db, check_redis

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
configure_logging(LOG_LEVEL)
log = logging.getLogger("api")

app = FastAPI(title="myapp-api", version="0.1.0")

# CORS (lab-friendly). En prod lo restringes.
allow_origins = os.getenv("CORS_ALLOW_ORIGINS", "*")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if allow_origins == "*" else [o.strip() for o in allow_origins.split(",")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics en /metrics
Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)


@app.middleware("http")
async def request_id_middleware(request: Request, call_next):
    incoming = request.headers.get("x-request-id")
    rid = set_request_id(incoming)
    response = await call_next(request)
    response.headers["x-request-id"] = rid
    return response


class EnqueueRequest(BaseModel):
    email: EmailStr
    payload: str


def map_state(celery_state: str) -> str:
    s = (celery_state or "").upper()
    if s in ("PENDING", "RECEIVED"):
        return "queued"
    if s in ("STARTED", "RETRY"):
        return "processing"
    if s == "SUCCESS":
        return "done"
    if s == "FAILURE":
        return "failed"
    return "queued"


# Health endpoints (root) - buenos para ALB healthchecks y probes
@app.get("/health")
def health():
    return {"ok": True}


@app.get("/ready")
def ready():
    r_ok, r_msg = check_redis()
    d_ok, d_msg = check_db()

    if not r_ok or not d_ok:
        log.warning("readiness_failed", extra={"redis": r_msg, "db": d_msg})
        raise HTTPException(status_code=503, detail={"redis": r_msg, "db": d_msg})

    return {"ok": True}


@app.get("/db-check")
def db_check():
    ok, msg = check_db()
    if not ok:
        raise HTTPException(status_code=503, detail=msg)
    return {"ok": True}


# Public API behind /api (porque ALB NO reescribe /api -> /)
public = APIRouter(prefix="/api")


@public.post("/enqueue")
def api_enqueue(req: EnqueueRequest):
    async_result = celery_app.send_task("jobs.process", args=[req.email, req.payload])
    log.info("job_enqueued", extra={"job_id": async_result.id, "email": req.email})
    return {"id": async_result.id, "status": "queued"}


@public.get("/jobs/{job_id}")
def api_job_status(job_id: str):
    res = celery_app.AsyncResult(job_id)
    status = map_state(res.state)

    payload = {"id": job_id, "status": status, "celery_state": res.state}
    if res.state == "FAILURE":
        payload["error"] = str(res.info)
    return payload


app.include_router(public)