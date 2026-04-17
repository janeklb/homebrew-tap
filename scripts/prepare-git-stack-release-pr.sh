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
formula_template_path="${FORMULA_TEMPLATE_PATH:-Formula/git-stack.rb.tmpl}"
output_path="${GITHUB_OUTPUT:-/dev/null}"

if [ ! -f "$formula_template_path" ]; then
  printf 'formula template not found: %s\n' "$formula_template_path" >&2
  exit 1
fi

extract_issue_field() {
  local label="$1"
  printf '%s\n' "$issue_body" | awk -v prefix="- ${label}: " '
    index($0, prefix) == 1 {
      value = substr($0, length(prefix) + 1)
      gsub(/`/, "", value)
      print value
      exit
    }
  '
}

resolve_tag_commit_and_date() {
  local tag="$1"
  local ref_json object_type object_sha

  ref_json="$(gh api "repos/${upstream_repo}/git/ref/tags/${tag}")"
  object_type="$(jq -r '.object.type' <<<"$ref_json")"
  object_sha="$(jq -r '.object.sha' <<<"$ref_json")"

  case "$object_type" in
    tag)
      local tag_json
      tag_json="$(gh api "repos/${upstream_repo}/git/tags/${object_sha}")"
      build_commit="$(jq -r '.object.sha' <<<"$tag_json")"
      build_date="$(jq -r '.tagger.date' <<<"$tag_json")"
      ;;
    commit)
      local commit_json
      build_commit="$object_sha"
      commit_json="$(gh api "repos/${upstream_repo}/git/commits/${object_sha}")"
      build_date="$(jq -r '.committer.date // .author.date' <<<"$commit_json")"
      ;;
    *)
      printf 'unsupported tag object type for %s: %s\n' "$tag" "$object_type" >&2
      exit 1
      ;;
  esac

  if [ -z "$build_commit" ] || [ "$build_commit" = "null" ] || [ -z "$build_date" ] || [ "$build_date" = "null" ]; then
    printf 'failed to resolve build metadata for %s\n' "$tag" >&2
    exit 1
  fi
}

issue_json="$(gh issue view "$issue_number" --repo "$tap_repo" --json number,title,body,url)"
issue_title="$(jq -r '.title' <<<"$issue_json")"
issue_body="$(jq -r '.body' <<<"$issue_json")"
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

if gh release download "$tag" --repo "$upstream_repo" --pattern homebrew-release.json --dir "$tmpdir" >/dev/null 2>&1; then
  source_url="$(jq -r '.source_url' "$metadata_path")"
  sha256="$(jq -r '.sha256' "$metadata_path")"
else
  source_url="$(extract_issue_field 'Source URL')"
  sha256="$(extract_issue_field 'SHA256')"
fi

if [ -z "$source_url" ] || [ -z "$sha256" ]; then
  printf 'missing source metadata for %s\n' "$tag" >&2
  exit 1
fi

resolve_tag_commit_and_date "$tag"

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
