#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <tag>" >&2
  exit 1
fi

tag="$1"
upstream_repo="${UPSTREAM_REPO:-janeklb/git-stack}"
formula_path="${FORMULA_PATH:-Formula/git-stack.rb}"
formula_template_path="${FORMULA_TEMPLATE_PATH:-Formula/git-stack.rb.erb}"
output_path="${GITHUB_OUTPUT:-/dev/null}"
release_url="https://github.com/${upstream_repo}/releases/tag/${tag}"

if [ ! -f "$formula_template_path" ]; then
  echo "formula template not found: $formula_template_path" >&2
  exit 1
fi

if [[ ! "$tag" =~ ^v[^[:space:]]+$ ]]; then
  echo "invalid tag: $tag" >&2
  exit 1
fi

version="${tag#v}"
tmpdir="$(mktemp -d)"
metadata_path="${tmpdir}/homebrew-release.json"

cleanup() {
  rm -rf "$tmpdir"
}

trap cleanup EXIT

gh release download "$tag" --repo "$upstream_repo" --pattern homebrew-release.json --dir "$tmpdir" >/dev/null

source_url="$(jq -r '.source_url' "$metadata_path")"
sha256="$(jq -r '.sha256' "$metadata_path")"
build_commit="$(jq -r '.build_commit' "$metadata_path")"
build_date="$(jq -r '.build_date' "$metadata_path")"

if [ -z "$source_url" ] || [ "$source_url" = "null" ] || \
   [ -z "$sha256" ] || [ "$sha256" = "null" ] || \
   [ -z "$build_commit" ] || [ "$build_commit" = "null" ] || \
   [ -z "$build_date" ] || [ "$build_date" = "null" ]; then
  echo "missing release metadata in $metadata_path for $tag" >&2
  exit 1
fi

ruby - "$formula_template_path" "$formula_path" "$source_url" "$sha256" "$build_commit" "$build_date" <<'RUBY'
require "erb"

formula_template_path, formula_path, release_source_url, release_sha256, release_build_commit, release_build_date = ARGV

template = File.read(formula_template_path)
rendered = ERB.new(template, trim_mode: "-").result(binding)
File.write(formula_path, rendered)
RUBY

branch_name="git-stack-release-${tag}"
pr_title="Update git-stack to ${tag}"

{
  echo "tag=$tag"
  echo "version=$version"
  echo "release_url=$release_url"
  echo "source_url=$source_url"
  echo "sha256=$sha256"
  echo "build_commit=$build_commit"
  echo "build_date=$build_date"
  echo "branch_name=$branch_name"
  echo "pr_title=$pr_title"

  if git diff --quiet -- "$formula_path"; then
    echo 'changed=false'
  else
    echo 'changed=true'
  fi
} >> "$output_path"
