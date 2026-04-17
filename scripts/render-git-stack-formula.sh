#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 6 ]; then
  printf 'usage: %s <source-url> <sha256> <build-commit> <build-date> <output-path> <template-path>\n' "$0" >&2
  exit 1
fi

source_url="$1"
sha256="$2"
build_commit="$3"
build_date="$4"
output_path="$5"
template_path="$6"

if [ ! -f "$template_path" ]; then
  printf 'formula template not found: %s\n' "$template_path" >&2
  exit 1
fi

ruby - "$template_path" "$output_path" "$source_url" "$sha256" "$build_commit" "$build_date" <<'RUBY'
require "erb"

template_path, output_path, release_source_url, release_sha256, release_build_commit, release_build_date = ARGV

template = File.read(template_path)
rendered = ERB.new(template, trim_mode: "-").result(binding)
File.write(output_path, rendered)
RUBY
