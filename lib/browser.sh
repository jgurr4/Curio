#!/usr/bin/env bash

curio_open_result_link() {
  local result_index="$1"
  local link_label="$2"
  local result_json
  local link_json
  local url
  local warnings_json
  local ai_safety_json
  local allow_open="yes"

  result_json="$(curio_session_result_json "$result_index")"
  [[ -n "$result_json" ]] || curio_die "No result found at index $result_index"

  link_json="$(jq -c --arg label "$link_label" '.links[]? | select(.label == $label)' <<<"$result_json" | head -n 1)"
  [[ -n "$link_json" ]] || curio_die "No link with label $link_label for result $result_index"
  url="$(jq -r '.url' <<<"$link_json")"

  warnings_json="$(curio_hard_link_warnings_json "$url")"
  ai_safety_json="$(curio_ai_check_link_safety "$result_json" "$link_json")"

  curio_note "Link review for $url"
  jq -r '
    [
      (.warnings[]?),
      ("AI: " + (.reason // "No reason provided"))
    ] | .[]
  ' <<<"$(jq -n --argjson hard "$warnings_json" --argjson ai "$ai_safety_json" '{warnings:$hard, reason:($ai.reason // "")}')" \
    | sed 's/^/- /'

  if jq -e '.safe == false' >/dev/null <<<"$ai_safety_json"; then
    allow_open="no"
  fi

  if [[ "$CURIO_WHOLESOMENESS" == "strict" && "$allow_open" == "no" ]]; then
    curio_die "Strict mode blocked this link due to safety concerns."
  fi

  printf 'Open this link in %s? [y/N] ' "$CURIO_BROWSER_PATH"
  local answer
  IFS= read -r answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    curio_note "Cancelled."
    return 0
  fi

  curio_note "Opening browser. Session duration policy: $CURIO_BROWSER_SESSION_DURATION_SECONDS seconds."
  "$CURIO_BROWSER_PATH" "$url" >/dev/null 2>&1 &
}

curio_hard_link_warnings_json() {
  local url="$1"
  local shorteners_json

  shorteners_json="$(curio_get_shortener_domains_json)"

  jq -n \
    --arg url "$url" \
    --argjson shorteners "$shorteners_json" \
    '
    [
      (if ($url | startswith("https://")) then empty else "Link is not HTTPS." end),
      (if ($url | test("[?&](utm_|fbclid=|gclid=|mc_eid=)")) then "Link has tracking or suspicious query parameters." else empty end),
      (
        ($url | capture("^[a-z]+://(?<host>[^/]+)")?.host // "")
        as $host
        | if ($shorteners | index($host)) then "Link uses a shortened domain." else empty end
      )
    ]
    '
}
