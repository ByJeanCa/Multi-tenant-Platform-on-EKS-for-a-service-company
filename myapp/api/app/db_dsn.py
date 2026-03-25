import os
from urllib.parse import quote_plus

def _read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read().strip()

def get_value(name: str, file_name: str | None = None) -> str | None:
    v = os.getenv(name)
    if v and v.strip():
        return v.strip()

    if file_name:
        fp = os.getenv(file_name)
        if fp and os.path.exists(fp):
            return _read_file(fp)

    return None

def build_database_url() -> str | None:
    host = get_value("DB_HOST")
    port = get_value("DB_PORT") or "5432"
    name = get_value("DB_NAME")


    user = get_value("DB_USER", "DB_USER_FILE")
    pwd  = get_value("DB_PASSWORD", "DB_PASSWORD_FILE")

    if not all([host, name, user, pwd]):
        return None

    user_enc = quote_plus(user)
    pwd_enc  = quote_plus(pwd)

    dsn = f"postgresql://{user_enc}:{pwd_enc}@{host}:{port}/{name}"
    return dsn