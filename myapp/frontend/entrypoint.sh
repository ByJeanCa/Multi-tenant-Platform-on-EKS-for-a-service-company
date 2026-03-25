#!/usr/bin/env sh
set -eu

API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"

# Render config.js desde template
export API_BASE_URL
envsubst < /usr/share/nginx/html/config.template.js > /usr/share/nginx/html/config.js

exec nginx -g 'daemon off;'