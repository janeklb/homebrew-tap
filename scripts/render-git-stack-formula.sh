#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 4 ] || [ "$#" -gt 6 ]; then
  printf 'usage: %s <source-url> <sha256> <build-commit> <build-date> [output-path] [template-path]\n' "$0" >&2
  exit 1
fi

source_url="$1"
sha256="$2"
build_commit="$3"
build_date="$4"
output_path="${5:-Formula/git-stack.rb}"
template_path="${6:-Formula/git-stack.rb.tmpl}"

if [ ! -f "$template_path" ]; then
  printf 'formula template not found: %s\n' "$template_path" >&2
  exit 1
fi

export RELEASE_SOURCE_URL="$source_url"
export RELEASE_SHA256="$sha256"
export RELEASE_BUILD_COMMIT="$build_commit"
export RELEASE_BUILD_DATE="$build_date"
export FORMULA_TEMPLATE_PATH="$template_path"
export FORMULA_OUTPUT_PATH="$output_path"

ruby <<'RUBY'
require "erb"

template_path = ENV.fetch("FORMULA_TEMPLATE_PATH")
output_path = ENV.fetch("FORMULA_OUTPUT_PATH")

release_source_url = ENV.fetch("RELEASE_SOURCE_URL")
release_sha256 = ENV.fetch("RELEASE_SHA256")
release_build_commit = ENV.fetch("RELEASE_BUILD_COMMIT")
release_build_date = ENV.fetch("RELEASE_BUILD_DATE")

template = File.read(template_path)
rendered = ERB.new(template, trim_mode: "-").result(binding)
File.write(output_path, rendered)
RUBY
