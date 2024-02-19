#!/bin/bash

set -e

sum() {
  sha256sum "$1" | cut -d' ' -f1
}

cut_sha256() {
  cut -d':' -f2
}

modify_config() {
  # Extract the parameters
  manifest_sha256=$1
  index=$2
  diff_sha256=$3

  # Read the manifest json file
  manifest_file="blobs/sha256/$manifest_sha256"

  # Modify the .rootfs.diff_ids[$index] value
  yq eval -r --inplace ".rootfs.diff_ids[$index] = \"sha256:$diff_sha256\"" "$manifest_file"

  # Calculate the SHA256 of the modified manifest file
  config_sha256=$(sum "$manifest_file")

  # Rename the manifest file
  config_file="blobs/sha256/$config_sha256"
  mv "$manifest_file" "$config_file"

  # Return the new SHA256 value
  echo "$config_sha256"
}
modify_manifest() {
  # Extract the sha256 value
  sha256=$1

  # Read the json file
  manifest_file="blobs/sha256/$sha256"
  layers=$(yq eval -r '.layers | length' "$manifest_file")

  # Loop through layers in reverse order
  for ((i = layers - 1; i >= 0; i--)); do
    size=$(yq eval -r ".layers[$i].size" "$manifest_file")
    if (( size > 1000000 )); then
      layer_sha256=$(yq eval -r ".layers[$i].digest" "$manifest_file" | cut_sha256)

      # Call your layer modification function
      modified_resp=$(modify_layer "$layer_sha256")
      new_layer_sha256=$(echo "$modified_resp" | cut -d' ' -f1)

      # Replace the old layer sha256 with the new one
      yq eval -r --inplace ".layers[$i].digest = \"sha256:$new_layer_sha256\"" "$manifest_file"
      yq eval -r --inplace ".layers[$i].size = $(stat -c%s "blobs/sha256/$new_layer_sha256")" "$manifest_file"

      # Call your modify_config function with the new layer sha256
      config_sha256=$(modify_config "$(yq eval -r ".config.digest" "$manifest_file" | cut_sha256)" "$i" "$(echo "$modified_resp" | cut -d' ' -f2)")
      yq eval -r --inplace ".config.digest = \"sha256:$config_sha256\"" "$manifest_file"
      yq eval -r --inplace ".config.size = $(stat -c%s "blobs/sha256/$config_sha256")" "$manifest_file"

      break
    fi
  done

  # Calculate the SHA256 of the modified manifest file
  manifest_new_sha256=$(sum "$manifest_file")
  mv "$manifest_file" "blobs/sha256/$manifest_new_sha256"

  # Return the new sha256 value
  echo "$manifest_new_sha256"
}

modify_layer() {
  # Extract the sha256 value
  sha256=$1

  # Extract the tar.gz file
  tar_file="blobs/sha256/$sha256"
  mv "$tar_file" "$sha256.tar.gz"
  gunzip "$sha256.tar.gz"

  tar --wildcards --delete '*.js.map' -f "$sha256.tar"
  diff_sha256=$(sum "$sha256.tar")
  gzip "$sha256.tar"

  # Calculate layer_sha256
  layer_sha256=$(sum "$sha256.tar.gz")

  # Rename the gzip file
  layer_file="blobs/sha256/$layer_sha256"
  mv "$sha256.tar.gz" "$layer_file"

  # Return layer_sha256 and diff_sha256
  echo "$layer_sha256 $diff_sha256"
}

modify_manifest_list() {
  index_file=$1
  if [ "$index_file" != "index.json" ]; then
    index_file="blobs/sha256/$index_file"
  fi
  media_type=$(yq eval -r '.mediaType' "$index_file")
  if [ "$media_type" != "application/vnd.oci.image.index.v1+json" ] && [ "$media_type" != "application/vnd.docker.distribution.manifest.list.v2+json" ]; then
    modify_manifest "$1"
  else
    manifest_length=$(yq eval -r '.manifests | length' "$index_file")
    # Loop through each digest
    for ((i = 0; i < manifest_length; i++)); do
      sha256=$(yq eval -r ".manifests[$i].digest" "$index_file" | cut_sha256)

      # Call your modify_manifest function with the sha256 value
      new_sha256=$(modify_manifest_list "$sha256")

      # Replace the old manifest sha256 with the new one
      yq eval -r --inplace ".manifests[$i].digest = \"sha256:$new_sha256\"" "$index_file"
      yq eval -r --inplace ".manifests[$i].size = $(stat -c%s "blobs/sha256/$new_sha256")" "$index_file"
    done
    # if index_file is not named index.json, rename it to sha256 of itself
    if [ "$index_file" != "index.json" ]; then
      index_sha256=$(sum "$index_file")
      mv "$index_file" "blobs/sha256/$index_sha256"
      echo "$index_sha256"
    fi
  fi
}

do_modify() {
  modify_manifest_list "index.json"
}


if [ -n "$1" ]; then
  cd "$1"
fi
do_modify