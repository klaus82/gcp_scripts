#!/bin/bash

readonly sql_instance="$(/usr/share/google/get_metadata_value attributes/sql-instance)"
readonly PROXY_DIR='/var/run/cloud_sql_proxy'
readonly PROXY_BIN='/usr/local/bin/cloud_sql_proxy'
readonly INIT_SCRIPT='/usr/lib/systemd/system/cloud-sql-proxy.service'

function install_cloud_sql_proxy() {
  # Install proxy.
  wget -q https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 \
    || err 'Unable to download cloud-sql-proxy binary'
  mv cloud_sql_proxy.linux.amd64 ${PROXY_BIN}
  chmod +x ${PROXY_BIN}

  mkdir -p ${PROXY_DIR}

  # Install proxy as systemd service for reboot tolerance.
  cat << EOF > ${INIT_SCRIPT}
[Unit]
Description=Google Cloud SQL Proxy
After=local-fs.target network-online.target
After=google.service
Before=shutdown.target

[Service]
Type=simple
ExecStart=${PROXY_BIN} \
  -dir=${PROXY_DIR} \
  -instances=${sql_instance}

[Install]
WantedBy=multi-user.target
EOF
  chmod a+rw ${INIT_SCRIPT}
  systemctl enable cloud-sql-proxy
  systemctl start cloud-sql-proxy \
    || err 'Unable to start cloud-sql-proxy service'

  echo 'Cloud SQL Proxy installation succeeded' >&2
}

function main() {
    install_cloud_sql_proxy
}

main
