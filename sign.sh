#!/bin/bash
set -eu

cd artifacts

mkdir ~/.gnupg
echo "$SIGNING_SECRING_B64" | base64 -d > ~/.gnupg/secring.gpg

echo "Signing ..."
find . -type f -print0 \
  | grep -zvP '(md5|sha\w*|asc)$' \
  | xargs -0 -n1 \
    gpg -u "$SIGNING_KEYNAME" --passphrase "$SIGNING_PASSPHRASE" --pinentry-mode loopback -ab --batch
echo "Signing Done"
echo

rm -Rf ~/.gnupg
