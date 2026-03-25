import os
import psycopg
import redis
from app.db_dsn import build_database_url

def check_redis() -> tuple[bool, str]:
    url = os.getenv("REDIS_URL", "redis://redis:6379/0")
    try:
        r = redis.Redis.from_url(
            url,
            socket_connect_timeout=1,
            socket_timeout=1,
            decode_responses=True,
        )
        r.ping()
        return True, "ok"
    except Exception as e:
        return False, f"redis_error: {type(e).__name__}: {e}"

def check_db() -> tuple[bool, str]:
    dsn = build_database_url()
    if not dsn:
        return False, "missing DB_HOST/DB_NAME/DB_USER/DB_PASSWORD (or *_FILE)"

    try:
        with psycopg.connect(dsn, connect_timeout=2) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1;")
                cur.fetchone()
        return True, "ok"
    except Exception as e:
        return False, f"db_error: {type(e).__name__}: {e}"