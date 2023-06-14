#!/usr/bin/env sh

mc alias set minio http://minio:9000 $MINIO_SERVER_ROOT_USER $MINIO_SERVER_ROOT_PASSWORD

setup_bucket() {
  mc mb minio/$1 --ignore-existing
}

setup_bucket test
setup_bucket production
setup_bucket public

mc anonymous set download minio/public
