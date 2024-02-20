# Grafana-sourcemap-less

This is a simple tool to generate Grafana docker images without sourcemap.

Take 8.5.27 as an example, which will reduce the image size by 42MB. (from 248MB to 206MB)

Inspired by [rules_oci](https://github.com/bazel-contrib/rules_oci) (using bash, crane and yq).

## code introduction

see [my blog](https://hunsh.net/20240219/%E5%A6%82%E4%BD%95%E4%BF%AE%E6%94%B9%E9%95%9C%E5%83%8F-layer%EF%BC%88%E4%BB%A5-sourcemap-less-grafana-%E4%B8%BA%E4%BE%8B%EF%BC%89/) (Chinese only)

## Usage
Because it is not clear how many people need sourcemap-less images,
there is no automation to push the processed images to dockerhub (which may occupy a large public space),
so **you can make them yourself**.

If it helps you, you can star this repo, so I will know how many people need this mirror image.

### prepare toolchain (crane and yq)
```bash
curl -fl https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
curl -fL https://github.com/google/go-containerregistry/releases/latest/download/go-containerregistry_Linux_x86_64.tar.gz | tar -C /usr/local/bin -xzf - crane
```

### get this script
```bash
wget https://raw.githubusercontent.com/hunshcn/grafana-sourcemap-less/master/handle.sh
```

### pull image
```bash
crane pull --format=oci "grafana/grafana:8.5.27" "./image"
```

### run script
```bash
bash handle.sh ./image
```

### push image
```bash
crane push ./image "yourregistry.com/grafana/grafana:8.5.27-sourcemap-less"
```
