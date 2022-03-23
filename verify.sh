#!/bin/bash
set -eu

cd artifacts

echo "Verifying origin of artifact content ..."
echo
find .
echo

ALLOWED_PATTERN=""
if [[ "$REPO" = "util" ]]; then
  ALLOWED_PATTERN='com/indeed/util-.*'
elif [[ "$REPO" = "status" ]]; then
  ALLOWED_PATTERN='com/indeed/status-.*'
elif [[ "$REPO" = "proctor" ]]; then
  ALLOWED_PATTERN='com/indeed/proctor-.*'
fi

if [[ "$ALLOWED_PATTERN" = "" ]]; then
  echo "Repo has no allowed publish pattern."
  exit 1
fi
ALLOWED_PATTERN="^./$ALLOWED_PATTERN/"

BAD_FILES="$(find . -type f -print0 | grep -zv "$ALLOWED_PATTERN" | tr '\0' '\n' || true)"
if [[ "$BAD_FILES" != "" ]]; then
  echo "Repo is not allowed to upload these files:"
  echo "$BAD_FILES"
  exit 1
fi

VERSIONS="$(find . -type f -print0 | grep -zvP 'maven-metadata\.xml(\.[\w]+)?$' | grep -zoP '/\K[^/]*(?=/[^/]*$)' | sort -z | uniq -z | tr '\0' '\n')"
echo "Found versions:"
echo "$VERSIONS"
echo
if [[ "$VERSIONS" = "" ]]; then
  echo "Failed to find publish version"
  exit 1
fi
if [[ "$(echo "$VERSIONS" | wc -l)" != "1" ]]; then
  echo "Publish can only contain one version number. Found multiple versions"
  exit 1
fi
#if [[ "$REF" != "" && "$VERSIONS" != *-dev-* ]]; then
#  echo "Non-main branches can only publish dev versions. If you are publishing main, the branch parameter should be left empty."
#  exit 1
#fi

echo "Verified"
echo
