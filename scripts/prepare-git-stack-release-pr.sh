#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'usage: %s <tag>\n' "$0" >&2
  exit 1
fi

tag="$1"
upstream_repo="${UPSTREAM_REPO:-janeklb/git-stack}"
formula_path="${FORMULA_PATH:-Formula/git-stack.rb}"
formula_template_path="${FORMULA_TEMPLATE_PATH:-Formula/git-stack.rb.erb}"
output_path="${GITHUB_OUTPUT:-/dev/null}"
release_url="https://github.com/${upstream_repo}/releases/tag/${tag}"

if [ ! -f "$formula_template_path" ]; then
  printf 'formula template not found: %s\n' "$formula_template_path" >&2
  exit 1
fi

if [[ ! "$tag" =~ ^v[^[:space:]]+$ ]]; then
  printf 'invalid tag: %s\n' "$tag" >&2
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
  printf 'missing release metadata in %s for %s\n' "$metadata_path" "$tag" >&2
  exit 1
fi

scripts/render-git-stack-formula.sh \
  "$source_url" \
  "$sha256" \
  "$build_commit" \
  "$build_date" \
  "$formula_path" \
  "$formula_template_path"

branch_name="git-stack-release-${tag}"
pr_title="Update git-stack to ${tag}"

printf 'tag=%s\n' "$tag" >> "$output_path"
printf 'version=%s\n' "$version" >> "$output_path"
printf 'release_url=%s\n' "$release_url" >> "$output_path"
printf 'source_url=%s\n' "$source_url" >> "$output_path"
printf 'sha256=%s\n' "$sha256" >> "$output_path"
printf 'build_commit=%s\n' "$build_commit" >> "$output_path"
printf 'build_date=%s\n' "$build_date" >> "$output_path"
printf 'branch_name=%s\n' "$branch_name" >> "$output_path"
printf 'pr_title=%s\n' "$pr_title" >> "$output_path"

if git diff --quiet -- "$formula_path"; then
  printf 'changed=false\n' >> "$output_path"
else
  printf 'changed=true\n' >> "$output_path"
fi
