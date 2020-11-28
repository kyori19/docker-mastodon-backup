#!/bin/sh

SAVEDATE=$(/bin/date +%Y%m%d%H%M)
ROOT_DIR="/tmp/${SAVEDATE}"

mkdir -p /root/.config/toot/
cat <<EOF > /root/.config/toot/config.json
{
  "active_user": "user@${TOOT_DOMAIN}",
  "apps": {
    "${TOOT_DOMAIN}": {
      "base_url": "https://${TOOT_DOMAIN}",
      "client_id": "",
      "client_secret": "",
      "instance": "${TOOT_DOMAIN}"
    }
  },
  "users": {
    "user@${TOOT_DOMAIN}": {
      "access_token": "${TOOT_ACCESS_TOKEN}",
      "instance": "${TOOT_DOMAIN}",
      "username": "user"
    }
  }
}
EOF

cat <<EOF | toot post
データベースのバックアップ作業を開始します
開始時刻: ${SAVEDATE}
EOF

mkdir -p "${ROOT_DIR}"

PGPASSWORD="${PSQL_PASSWORD}" pg_dumpall -h "${PSQL_HOST}" -U postgres > "${ROOT_DIR}/dumpall.sql"

redis-cli -h "${REDIS_HOST}" -a "${REDIS_PASSWORD}" --rdb "${ROOT_DIR}/dump.rdb"

tar -czvf "${ROOT_DIR}.tar.gz" -C /tmp "${SAVEDATE}/"

cat <<EOF | toot post
バックアップファイルを作成しました。オブジェクトストレージに転送します
開始時刻: ${SAVEDATE}
EOF

s3cmd put "${ROOT_DIR}.tar.gz" "s3://${S3_BUCKET}" --host-bucket "%(bucket)s.${S3_HOST}" --access_key "${S3_ACCESS_KEY}" --secret_key "${S3_ACCESS_SECRET}"
rm -r ${ROOT_DIR}*
set $(s3cmd ls "s3://${S3_BUCKET}" --host-bucket "%(bucket)s.${S3_HOST}" --access_key "${S3_ACCESS_KEY}" --secret_key "${S3_ACCESS_SECRET}")
s3cmd rm ${4} --host-bucket "%(bucket)s.${S3_HOST}" --access_key "${S3_ACCESS_KEY}" --secret_key "${S3_ACCESS_SECRET}"

cat <<EOF | toot post
データベースのバックアップ作業が完了しました
開始時刻: ${SAVEDATE}
EOF
