#!/usr/bin/env bash

curio_die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

curio_warn() {
  printf 'Warning: %s\n' "$*" >&2
}

curio_note() {
  printf '%s\n' "$*"
}

curio_require_command() {
  command -v "$1" >/dev/null 2>&1 || curio_die "Missing required command: $1"
}

curio_slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

curio_trim() {
  printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

curio_json_escape() {
  jq -Rn --arg value "$1" '$value'
}

curio_parse_shell_words() {
  python3 - "$1" <<'PY'
import json
import shlex
import sys

try:
    print(json.dumps(shlex.split(sys.argv[1])))
except ValueError as exc:
    print(str(exc), file=sys.stderr)
    sys.exit(1)
PY
}
