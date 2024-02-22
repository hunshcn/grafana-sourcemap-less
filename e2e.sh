#!/usr/bin/env bash

curl -fl https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
curl -fL https://github.com/google/go-containerregistry/releases/latest/download/go-containerregistry_Linux_x86_64.tar.gz | tar -C /usr/local/bin -xzf - crane

crane pull --format=oci "grafana/grafana:10.3.3" "./image"
bash handle.sh ./image

if find ./image/blobs -type f -size +1M -exec tar tzf {} \; | grep js.map > /dev/null; then
  echo 'fail!'
  exit 1
fi
