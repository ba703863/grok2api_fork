#!/bin/sh
set -eu

umask 077

# A mounted volume arrives owned by root, which the unprivileged runtime user
# cannot write — take ownership of the data dir on every start.
data_dir=/app/data
mkdir -p "${data_dir}"
chown -R grok2api:grok2api "${data_dir}"
chmod 0700 "${data_dir}"

quality_guard_dir=/var/lib/grok2api-quality-guard
mkdir -p "${quality_guard_dir}"
chown grok2api:grok2api "${quality_guard_dir}"
chmod 0700 "${quality_guard_dir}"

# Railway (and other mount-less platforms) cannot bind-mount a file, so allow
# the config to arrive as a base64 env var and be materialized at startup.
if [ ! -f "${GROK2API_CONFIG_SOURCE}" ] && [ -n "${GROK2API_CONFIG_B64:-}" ]; then
  mkdir -p "$(dirname "${GROK2API_CONFIG_SOURCE}")"
  printf '%s' "${GROK2API_CONFIG_B64}" | base64 -d > "${GROK2API_CONFIG_SOURCE}"
  echo "materialized config from GROK2API_CONFIG_B64" >&2
fi

if [ ! -f "${GROK2API_CONFIG_SOURCE}" ]; then
  echo "missing config: ${GROK2API_CONFIG_SOURCE}" >&2
  echo "mount config.yaml to /run/grok2api/config.yaml, or set GROK2API_CONFIG_B64" >&2
  exit 1
fi

cp "${GROK2API_CONFIG_SOURCE}" /app/config.yaml
chown grok2api:grok2api /app/config.yaml
chmod 0600 /app/config.yaml

exec su-exec grok2api:grok2api "$@"
