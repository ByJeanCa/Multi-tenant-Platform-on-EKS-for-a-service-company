FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN useradd -m appuser

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY entrypoint.sh /app/entrypoint.sh
COPY app /app/app

RUN chmod +x /app/entrypoint.sh
USER appuser

CMD ["/app/entrypoint.sh"]