#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'usage: %s <issue-number>\n' "$0" >&2
  exit 1
fi

issue_number="$1"
tap_repo="${TAP_REPO:-${GITHUB_REPOSITORY:-janeklb/homebrew-tap}}"
upstream_repo="${UPSTREAM_REPO:-janeklb/git-stack}"
formula_path="${FORMULA_PATH:-Formula/git-stack.rb}"
formula_template_path="${FORMULA_TEMPLATE_PATH:-Formula/git-stack.rb.erb}"
output_path="${GITHUB_OUTPUT:-/dev/null}"

if [ ! -f "$formula_template_path" ]; then
  printf 'formula template not found: %s\n' "$formula_template_path" >&2
  exit 1
fi

issue_json="$(gh issue view "$issue_number" --repo "$tap_repo" --json number,title,body,url)"
issue_title="$(jq -r '.title' <<<"$issue_json")"
issue_url="$(jq -r '.url' <<<"$issue_json")"

if [[ ! "$issue_title" =~ ^\[git-stack\]\ Release\ (v[^[:space:]]+)$ ]]; then
  printf 'skip=true\n' >> "$output_path"
  printf 'issue %s does not look like a git-stack release handoff\n' "$issue_number"
  exit 0
fi

tag="${BASH_REMATCH[1]}"
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

printf 'skip=false\n' >> "$output_path"
printf 'issue_number=%s\n' "$issue_number" >> "$output_path"
printf 'issue_url=%s\n' "$issue_url" >> "$output_path"
printf 'tag=%s\n' "$tag" >> "$output_path"
printf 'version=%s\n' "$version" >> "$output_path"
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
