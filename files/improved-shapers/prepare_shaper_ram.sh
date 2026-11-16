#!/bin/sh
rm -f /tmp/*raw_data* /tmp/*resonances* 2>/dev/null || true
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
: > /tmp/shaper_paused_services
if [ -x /opt/bin/supervisorctl ]; then
  for svc in octoeverywhere obico mobileraker octoapp simplyprint; do
    if /opt/bin/supervisorctl status "$svc" 2>/dev/null | grep -q "RUNNING"; then
      echo "$svc" >> /tmp/shaper_paused_services
      /opt/bin/supervisorctl stop "$svc" >/dev/null 2>&1 || true
    fi
  done
fi
