FROM kyori/cron:alpine

COPY --from=postgres:13.3-alpine /lib/libssl.so.1.1 /lib/libcrypto.so.1.1 /lib/
COPY --from=postgres:13.3-alpine /usr/local/lib/libpq.so.5 /usr/local/lib/libpq.so.5
COPY --from=postgres:13.3-alpine /usr/local/bin/pg_dump /usr/local/bin/pg_dumpall /usr/local/bin/

COPY --from=redis:5.0.7-alpine /usr/local/bin/redis-cli /usr/local/bin/redis-cli

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories &&\
  echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories &&\
  echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories &&\
  apk upgrade musl &&\
  apk add --no-cache tzdata ca-certificates python3 py3-pip toot &&\
  pip3 install --upgrade pip &&\
  pip3 install s3cmd==2.2.0 &&\
  rm -rf /root/.cache/pip

COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

CMD [ "/bin/sh", "-c",  "start-cron \"${CRON_TIMER} /backup.sh >> /var/log/cron.log 2>&1\"" ]
