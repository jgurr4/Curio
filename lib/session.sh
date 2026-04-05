#!/usr/bin/env bash

CURIO_SESSION_PATH="${CURIO_SESSION_PATH:-$CURIO_STATE_DIR/session.json}"

curio_session_init() {
  if [[ ! -f "$CURIO_SESSION_PATH" ]]; then
    printf '{"results":[],"last_query":null,"history":[]}\n' >"$CURIO_SESSION_PATH"
  fi
}

curio_session_store_results() {
  local category="$1"
  local tags="$2"
  local results_json="$3"
  jq \
    --arg category "$category" \
    --arg tags "$tags" \
    --argjson results "$results_json" \
    '.results = $results | .last_query = {category: $category, tags: $tags}' \
    "$CURIO_SESSION_PATH" >"$CURIO_SESSION_PATH.tmp"
  mv "$CURIO_SESSION_PATH.tmp" "$CURIO_SESSION_PATH"
}

curio_session_result_json() {
  local index="$1"
  jq -c --argjson index "$index" '.results[$index - 1] // empty' "$CURIO_SESSION_PATH"
}

curio_show_results() {
  jq -r '
    if (.results | length) == 0 then
      "No active results in session."
    else
      .results
      | to_entries[]
      | "\(.key + 1). \(.value.title)\n   Year: \(.value.year // "Unknown") | Rating: \(.value.rating // "Unknown") | Relevance: \(.value.relevance_score // "n/a")\n   Source: \(.value.source // "unknown")\n   Description: \(.value.description // "No description")\n   Links: \((.value.links // []) | map("\(.label)=\(.url)") | join(", "))\n"
    end
  ' "$CURIO_SESSION_PATH"
}
