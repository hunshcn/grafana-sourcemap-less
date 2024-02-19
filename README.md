# Grafana-sourcemap-less

This is a simple tool to generate Grafana docker images without sourcemap.

Take 8.5.27 as an example, which will reduce the image size by 42MB. (from 248MB to 206MB)

Inspired by [rules_oci](https://github.com/bazel-contrib/rules_oci) (using bash, crane and yq).

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

### clone this repo
```bash
git clone https://github.com/hunshcn/grafana-sourcemap-less.git
cd grafana-sourcemap-less
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
