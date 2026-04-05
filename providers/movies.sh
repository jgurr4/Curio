#!/usr/bin/env bash

curio_discover_movies() {
  local tags=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tags)
        tags="${2:-}"
        shift 2
        ;;
      *)
        curio_die "Unknown argument for discover movies: $1"
        ;;
    esac
  done

  [[ -n "$tags" ]] || curio_die "Usage: curio discover movies --tags \"...\""

  curio_note "Searching IMDb candidates..."
  local raw_candidates_json
  raw_candidates_json="$(curio_movies_fetch_candidates "$tags")"

  curio_note "Applying hard filters..."
  local filtered_candidates_json
  filtered_candidates_json="$(curio_movies_apply_hard_filters "$raw_candidates_json")"

  if [[ "$(jq 'length' <<<"$filtered_candidates_json")" == "0" ]]; then
    curio_note "No safe movie candidates were found for that query."
    curio_session_store_results "movies" "$tags" '[]'
    return 0
  fi

  curio_note "Requesting AI curation..."
  local curated_json
  curated_json="$(curio_ai_curate_results "movies" "$tags" "$filtered_candidates_json")"

  local results_json
  if ! results_json="$(jq -ce '.results // []' <<<"$curated_json" 2>/dev/null)"; then
    curio_warn "AI returned invalid JSON. Falling back to hard-filtered candidates."
    results_json="$filtered_candidates_json"
  fi
  curio_session_store_results "movies" "$tags" "$results_json"
  curio_show_results
}

curio_movies_fetch_candidates() {
  local tags="$1"
  local imdb_json
  local fallback_json

  imdb_json="$(curio_movies_fetch_imdb_suggestions "$tags" || true)"
  if [[ -n "$imdb_json" && "$(jq 'length' <<<"$imdb_json" 2>/dev/null || printf '0')" != "0" ]]; then
    printf '%s\n' "$imdb_json"
    return 0
  fi

  curio_warn "IMDb primary fetch failed or returned no candidates. Falling back to DuckDuckGo site search."
  fallback_json="$(curio_movies_fetch_duckduckgo_site_results "$tags" || true)"
  if [[ -n "$fallback_json" && "$(jq 'length' <<<"$fallback_json" 2>/dev/null || printf '0')" != "0" ]]; then
    printf '%s\n' "$fallback_json"
    return 0
  fi

  printf '[]\n'
}

curio_movies_fetch_imdb_suggestions() {
  local tags="$1"
  local query_encoded
  local first_char
  local url

  query_encoded="$(jq -rn --arg v "$tags" '$v|@uri')"
  first_char="$(printf '%s' "$tags" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[^a-z0-9]*([a-z0-9]).*$/\1/')"
  [[ -n "$first_char" ]] || first_char="x"

  url="https://v3.sg.media-imdb.com/suggestion/${first_char}/${query_encoded}.json"

  curl -fsSL "$url" \
  | jq -c '
      (.d // [])
      | map({
          title: (.l // .title // "Unknown"),
          year: (.y | tostring // "Unknown"),
          source: "IMDb",
          source_id: (.id // ""),
          source_url: (if (.id // "") != "" then "https://www.imdb.com/title/" + .id + "/" else "" end),
          description: (.s // ""),
          links: [
            {
              label: "A",
              kind: "research",
              url: (if (.id // "") != "" then "https://www.imdb.com/title/" + .id + "/" else "https://www.imdb.com/find/?q=" + ((.l // "") | @uri) end),
              trust_score: 8
            }
          ]
        })
    '
}

curio_movies_fetch_duckduckgo_site_results() {
  local tags="$1"
  local query_encoded
  local url

  query_encoded="$(jq -rn --arg v "site:imdb.com/title movie $tags" '$v|@uri')"
  url="https://html.duckduckgo.com/html/?q=${query_encoded}"

  curl -fsSL "$url" \
  | python3 -c '
import json
import re
import sys

html = sys.stdin.read()
pattern = re.compile(r"<a[^>]+class=\"result__a\"[^>]+href=\"([^\"]+)\"[^>]*>(.*?)</a>", re.I | re.S)
results = []
for href, title_html in pattern.findall(html):
    title = re.sub(r"<.*?>", "", title_html)
    title = re.sub(r"\s+", " ", title).strip()
    if "imdb.com/title/" not in href:
        continue
    results.append({
        "title": title or "Unknown",
        "year": "Unknown",
        "source": "DuckDuckGo+IMDb",
        "source_id": "",
        "source_url": href,
        "description": "",
        "links": [{"label": "A", "kind": "research", "url": href, "trust_score": 6}]
    })
    if len(results) >= 25:
        break
print(json.dumps(results))
'
}

curio_movies_apply_hard_filters() {
  local candidates_json="$1"
  local filter_terms_json
  filter_terms_json="$(curio_get_filter_terms_json)"

  jq -c \
    --argjson blocked "$filter_terms_json" \
    '
    map(
      select(
        (
          [(.title // ""), (.description // "")]
          | join(" ")
          | ascii_downcase
        ) as $haystack
        | ($blocked | all(. as $word | ($haystack | contains($word | ascii_downcase) | not)))
      )
    )
    ' <<<"$candidates_json"
}
