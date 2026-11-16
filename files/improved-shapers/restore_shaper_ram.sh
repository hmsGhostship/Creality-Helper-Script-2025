#!/bin/sh
if [ -f /tmp/shaper_paused_services ] && [ -x /opt/bin/supervisorctl ]; then
  while IFS= read -r svc; do
    [ -n "$svc" ] && /opt/bin/supervisorctl start "$svc" >/dev/null 2>&1 || true
  done < /tmp/shaper_paused_services
  rm -f /tmp/shaper_paused_services
fi
