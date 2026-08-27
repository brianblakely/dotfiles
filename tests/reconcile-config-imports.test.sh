#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
reconciler=${RECONCILER:-"$repo_root/scripts/reconcile-config-imports"}
test_root=$(mktemp -d)
test_count=0

cleanup() {
  if [[ $test_root == /tmp/* && -d $test_root ]]; then
    rm -rf -- "$test_root"
  fi
}
trap cleanup EXIT

fail() {
  printf 'not ok %d - %s\n' "$((test_count + 1))" "$*" >&2
  exit 1
}

pass() {
  test_count=$((test_count + 1))
  printf 'ok %d - %s\n' "$test_count" "$1"
}

assert_files_equal() {
  local expected=$1
  local actual=$2
  local description=$3
  if ! cmp -s -- "$expected" "$actual"; then
    diff -u -- "$expected" "$actual" >&2 || true
    fail "$description"
  fi
}

ensure_block() {
  "$reconciler" ensure-block \
    "$1" "$2" \
    '# BEGIN home-manager: test import' \
    'include repo.conf' \
    '# END home-manager: test import' \
    'include repo.conf' >/dev/null
}

make_case() {
  local name=$1
  local directory="$test_root/$name"
  mkdir -p -- "$directory"
  printf '%s\n' 'repo content' > "$directory/repo.conf"
  printf '%s\n' "$directory"
}

# 1. A missing block is appended.
case_dir=$(make_case missing-block)
printf 'canonical content\n' > "$case_dir/canonical.conf"
ensure_block "$case_dir/canonical.conf" "$case_dir/repo.conf"
printf 'canonical content\n# BEGIN home-manager: test import\ninclude repo.conf\n# END home-manager: test import\n' > "$case_dir/expected"
assert_files_equal "$case_dir/expected" "$case_dir/canonical.conf" 'missing block was not added correctly'
pass 'missing managed block is added'

# 2. A second run produces exactly the same bytes.
cp -- "$case_dir/canonical.conf" "$case_dir/first-run"
inode_before=$(stat -c '%i' "$case_dir/canonical.conf")
mtime_before=$(stat -c '%y' "$case_dir/canonical.conf")
ensure_block "$case_dir/canonical.conf" "$case_dir/repo.conf"
assert_files_equal "$case_dir/first-run" "$case_dir/canonical.conf" 'second run changed the file'
[[ $(stat -c '%i' "$case_dir/canonical.conf") == "$inode_before" ]] || fail 'second run replaced the file'
[[ $(stat -c '%y' "$case_dir/canonical.conf") == "$mtime_before" ]] || fail 'second run changed the timestamp'
pass 'reconciliation is idempotent'

# 3. Unrelated bytes before the block are preserved.
case_dir=$(make_case preserve-content)
printf 'first line\n\n  whitespace stays  \nlast line\n' > "$case_dir/prefix"
cp -- "$case_dir/prefix" "$case_dir/canonical.conf"
ensure_block "$case_dir/canonical.conf" "$case_dir/repo.conf"
sed '/^# BEGIN home-manager: test import$/,$d' "$case_dir/canonical.conf" > "$case_dir/actual-prefix"
assert_files_equal "$case_dir/prefix" "$case_dir/actual-prefix" 'unrelated canonical content changed'
pass 'unrelated canonical content is preserved byte-for-byte'

# 4. A stale body is repaired without duplicating the block.
case_dir=$(make_case stale-block)
printf 'before\n# BEGIN home-manager: test import\ninclude old.conf\n# END home-manager: test import\n' > "$case_dir/canonical.conf"
ensure_block "$case_dir/canonical.conf" "$case_dir/repo.conf"
printf 'before\n# BEGIN home-manager: test import\ninclude repo.conf\n# END home-manager: test import\n' > "$case_dir/expected"
assert_files_equal "$case_dir/expected" "$case_dir/canonical.conf" 'stale block was not repaired'
[[ $(grep -Fc '# BEGIN home-manager: test import' "$case_dir/canonical.conf") == 1 ]] || fail 'BEGIN marker was duplicated'
pass 'old managed block is replaced rather than duplicated'

# 5. A block in the middle is moved to the end.
case_dir=$(make_case middle-block)
printf 'before\n# BEGIN home-manager: test import\ninclude repo.conf\n# END home-manager: test import\nafter\n' > "$case_dir/canonical.conf"
ensure_block "$case_dir/canonical.conf" "$case_dir/repo.conf"
printf 'before\nafter\n# BEGIN home-manager: test import\ninclude repo.conf\n# END home-manager: test import\n' > "$case_dir/expected"
assert_files_equal "$case_dir/expected" "$case_dir/canonical.conf" 'middle block was not moved to the end'
pass 'managed block in the middle is moved to the end'

# 6. Content an external migration adds after the block survives.
case_dir=$(make_case external-migration)
printf 'before\n# BEGIN home-manager: test import\ninclude repo.conf\n# END home-manager: test import\nnew external content\n' > "$case_dir/canonical.conf"
ensure_block "$case_dir/canonical.conf" "$case_dir/repo.conf"
printf 'before\nnew external content\n# BEGIN home-manager: test import\ninclude repo.conf\n# END home-manager: test import\n' > "$case_dir/expected"
assert_files_equal "$case_dir/expected" "$case_dir/canonical.conf" 'external content after the block was lost'
pass 'new canonical content after the block survives'

# 7. Missing canonical files fail clearly.
case_dir=$(make_case missing-canonical)
if ensure_block "$case_dir/missing.conf" "$case_dir/repo.conf" 2> "$case_dir/error"; then
  fail 'missing canonical file unexpectedly succeeded'
fi
grep -Fq 'canonical file does not exist:' "$case_dir/error" || fail 'missing canonical error was unclear'
pass 'missing canonical file fails clearly'

# 8. Missing repo source files fail clearly.
case_dir=$(make_case missing-source)
printf 'canonical\n' > "$case_dir/canonical.conf"
if ensure_block "$case_dir/canonical.conf" "$case_dir/missing repo.conf" 2> "$case_dir/error"; then
  fail 'missing repo source unexpectedly succeeded'
fi
grep -Fq 'referenced repo file does not exist:' "$case_dir/error" || fail 'missing repo source error was unclear'
pass 'missing repo source file fails clearly'

# 9. Canonical and source paths containing spaces work.
case_dir=$(make_case 'paths with spaces')
mv -- "$case_dir/repo.conf" "$case_dir/repo source.conf"
printf 'spaced path content\n' > "$case_dir/canonical file.conf"
ensure_block "$case_dir/canonical file.conf" "$case_dir/repo source.conf"
printf 'spaced path content\n# BEGIN home-manager: test import\ninclude repo.conf\n# END home-manager: test import\n' > "$case_dir/expected file"
assert_files_equal "$case_dir/expected file" "$case_dir/canonical file.conf" 'paths containing spaces failed'
pass 'paths containing spaces work'

# 10. Reconciliation preserves mode and never creates a symlink.
case_dir=$(make_case ordinary-file)
printf 'permissions\n' > "$case_dir/canonical.conf"
chmod 0640 "$case_dir/canonical.conf"
ensure_block "$case_dir/canonical.conf" "$case_dir/repo.conf"
[[ -f $case_dir/canonical.conf && ! -L $case_dir/canonical.conf ]] || fail 'canonical path is not an ordinary file'
[[ $(stat -c '%a' "$case_dir/canonical.conf") == 640 ]] || fail 'canonical permissions changed'
if find "$test_root" -type l -print -quit | grep -q .; then
  fail 'a tested configuration path became a symlink'
fi
pass 'ordinary-file type and reasonable permissions are preserved'

# The unmarked line used by the old installer is migrated into one block.
case_dir=$(make_case legacy-line)
printf 'before\ninclude repo.conf\nafter\ninclude repo.conf\n' > "$case_dir/canonical.conf"
ensure_block "$case_dir/canonical.conf" "$case_dir/repo.conf"
[[ $(grep -Fc 'include repo.conf' "$case_dir/canonical.conf") == 1 ]] || fail 'legacy imports were duplicated'
pass 'legacy unmarked imports are deduplicated'

printf '1..%d\n' "$test_count"
