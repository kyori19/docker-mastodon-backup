FROM alpine:3.22

COPY --from=postgres:17.5-alpine /usr/local/lib/libpq.so.5 /usr/local/lib/libpq.so.5
COPY --from=postgres:17.5-alpine /usr/local/bin/pg_dump /usr/local/bin/pg_dumpall /usr/local/bin/

COPY --from=kyori/cron:alpine /usr/sbin/start-cron /usr/sbin/start-cron

COPY --from=redis:8.0.6-alpine /usr/local/bin/redis-cli /usr/local/bin/redis-cli

# An optional CA bundle supports builds behind an HTTPS inspection proxy.
# Keep pip packages separate from Alpine's system Python (PEP 668).
RUN --mount=type=secret,id=proxy_ca \
  set -eu; \
  build_ca=/etc/ssl/certs/ca-certificates.crt; \
  if [ -f /run/secrets/proxy_ca ]; then build_ca=/run/secrets/proxy_ca; fi; \
  SSL_CERT_FILE="$build_ca" apk add --no-cache bash tzdata ca-certificates python3 libmagic toot \
    libssl3 libcrypto3 krb5-libs libldap lz4-libs zstd-libs; \
  SSL_CERT_FILE="$build_ca" apk add --no-cache --virtual .build-deps py3-pip; \
  python3 -m venv --without-pip /opt/venv; \
  PIP_CERT="$build_ca" pip3 --python /opt/venv/bin/python install --no-cache-dir s3cmd==2.4.0; \
  apk del .build-deps

ENV PATH="/opt/venv/bin:${PATH}"

COPY backup.sh /backup.sh
# Preserve cron wildcards and follow new log output without a busy loop.
RUN chmod +x /backup.sh && \
  sed -i -e 's/echo -e ${cron_job}/echo -e "${cron_job}"/' \
    -e 's|cat /var/log/cron.log|tail -F /var/log/cron.log|' /usr/sbin/start-cron

CMD [ "/bin/sh", "-c",  "start-cron \"${CRON_TIMER} /backup.sh >> /var/log/cron.log 2>&1\"" ]
