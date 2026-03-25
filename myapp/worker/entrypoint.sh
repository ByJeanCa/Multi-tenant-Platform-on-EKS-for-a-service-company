#!/usr/bin/env sh
set -eu

# Backoff simple antes de arrancar Celery
REDIS_URL="${REDIS_URL:-redis://redis:6379/0}"

i=0
sleep_s=1
max_attempts="${REDIS_STARTUP_MAX_ATTEMPTS:-12}"

echo "Checking Redis connectivity before starting worker..."

while [ "$i" -lt "$max_attempts" ]; do
  python - <<PY
import os, sys
import redis
url = os.environ.get("REDIS_URL")
try:
    r = redis.Redis.from_url(url, socket_connect_timeout=1, socket_timeout=1)
    r.ping()
    print("Redis OK")
    sys.exit(0)
except Exception as e:
    print(f"Redis not ready: {type(e).__name__}: {e}")
    sys.exit(1)
PY
  code=$?
  if [ "$code" -eq 0 ]; then
    break
  fi

  i=$((i+1))
  echo "Retrying in ${sleep_s}s... (attempt ${i}/${max_attempts})"
  sleep "$sleep_s"
  if [ "$sleep_s" -lt 30 ]; then
    sleep_s=$((sleep_s*2))
  fi
done

if [ "$i" -ge "$max_attempts" ]; then
  echo "Redis still not reachable after ${max_attempts} attempts. Exiting (let Kubernetes restart)."
  exit 1
fi

LOG_LEVEL="${LOG_LEVEL:-INFO}"
CONCURRENCY="${CELERY_CONCURRENCY:-2}"

exec celery -A app.worker.celery_app worker \
  --loglevel="${LOG_LEVEL}" \
  --concurrency="${CONCURRENCY}"