#!/usr/bin/env bash
set -euo pipefail

test "$(id -u)" -ne 0
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir "$work_dir/doc" "$work_dir/docx"
printf '%s\n' '{\rtf1\ansi Runner DOC conversion smoke test}' > "$work_dir/source.rtf"

timeout 60s soffice --headless --nologo --nodefault --nofirststartwizard \
    "-env:UserInstallation=file://$work_dir/profile-export" \
    --convert-to 'doc:MS Word 97' --outdir "$work_dir/doc" "$work_dir/source.rtf"
test -s "$work_dir/doc/source.doc"
test "$(od -An -tx1 -N8 "$work_dir/doc/source.doc" | tr -d ' \n')" = d0cf11e0a1b11ae1

timeout 60s soffice --headless --nologo --nodefault --nofirststartwizard \
    "-env:UserInstallation=file://$work_dir/profile-import" \
    --infilter='MS Word 97' --convert-to 'docx:Office Open XML Text' \
    --outdir "$work_dir/docx" "$work_dir/doc/source.doc"
test -s "$work_dir/docx/source.docx"
unzip -p "$work_dir/docx/source.docx" word/document.xml > "$work_dir/document.xml"
grep -q 'Runner DOC conversion smoke test' "$work_dir/document.xml"
soffice --headless --version
echo 'Binary DOC conversion passed as the runner user.'
