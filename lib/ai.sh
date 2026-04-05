#!/usr/bin/env bash

curio_ai_auth_args() {
  if [[ -n "$CURIO_AI_BASIC_AUTH_USER" || -n "$CURIO_AI_BASIC_AUTH_PASSWORD" ]]; then
    printf -- '-u\n%s:%s\n' "$CURIO_AI_BASIC_AUTH_USER" "$CURIO_AI_BASIC_AUTH_PASSWORD"
  fi
}

curio_ai_system_prompt() {
  case "$CURIO_WHOLESOMENESS" in
    strict)
      cat <<'EOF'
You are Curio's strict curator. Remove any result that appears vulgar, sexually suggestive, graphically violent, spiritually unhealthy, manipulative, or irrelevant. Return only safe, highly relevant options. Prefer conservative judgments.
EOF
      ;;
    balanced)
      cat <<'EOF'
You are Curio's balanced curator. Remove results that appear inappropriate, exploitative, manipulative, excessively vulgar, graphically violent, or irrelevant. Keep useful mainstream options if they are not obviously unsafe.
EOF
      ;;
    open)
      cat <<'EOF'
You are Curio's open curator. Prioritize relevance and quality. Only remove results that are clearly unsafe, deceptive, malicious, or badly mismatched to the user's request.
EOF
      ;;
  esac
}

curio_ai_generate_stream_to_text() {
  local prompt="$1"
  local format="${2:-}"
  local request_json
  local auth_args=()

  if [[ -n "$format" ]]; then
    request_json="$(jq -n \
      --arg model "$CURIO_AI_MODEL" \
      --arg system "$(curio_ai_system_prompt)" \
      --arg prompt "$prompt" \
      --arg format "$format" \
      '{model:$model, system:$system, prompt:$prompt, stream:true, format:$format}')"
  else
    request_json="$(jq -n \
      --arg model "$CURIO_AI_MODEL" \
      --arg system "$(curio_ai_system_prompt)" \
      --arg prompt "$prompt" \
      '{model:$model, system:$system, prompt:$prompt, stream:true}')"
  fi

  if [[ -n "$CURIO_AI_BASIC_AUTH_USER" || -n "$CURIO_AI_BASIC_AUTH_PASSWORD" ]]; then
    auth_args=(-u "${CURIO_AI_BASIC_AUTH_USER}:${CURIO_AI_BASIC_AUTH_PASSWORD}")
  fi

  curl -sS "${auth_args[@]}" \
    -H 'Content-Type: application/json' \
    -d "$request_json" \
    "$CURIO_AI_BASE_URL/api/generate" \
  | jq -rs 'map(.response // "") | join("")'
}

curio_ai_curate_results() {
  local category="$1"
  local tags="$2"
  local raw_candidates_json="$3"
  local prompt

  prompt="$(cat <<EOF
Category: $category
User tags: $tags
Maximum results: $CURIO_RESULTS_CAP

Take the raw candidates below and return strict JSON with this schema:
{
  "results": [
    {
      "title": "string",
      "year": "string",
      "created_by": "string",
      "rating": "string",
      "description": "string",
      "relevance_score": 0.0,
      "source": "string",
      "links": [
        {"label":"A","kind":"buy|research|watch","url":"https://...","trust_score":8}
      ]
    }
  ]
}

Rules:
- Remove irrelevant candidates.
- Respect the wholesomeness policy from the system prompt.
- Limit the output to the maximum results.
- Keep descriptions short and text-only.
- Provide realistic trust scores from 1 to 10.
- If created_by or rating is unknown, use "Unknown".

Raw candidates JSON:
$raw_candidates_json
EOF
)"

  curio_ai_generate_stream_to_text "$prompt" "json"
}

curio_ai_answer_about_result() {
  local result_index="$1"
  local question="$2"
  local result_json
  local prompt

  result_json="$(curio_session_result_json "$result_index")"
  [[ -n "$result_json" ]] || curio_die "No result found at index $result_index"

  prompt="$(cat <<EOF
The user is asking about this selected result:
$result_json

Question:
$question

Answer concisely in plain text. Respect the configured wholesomeness level.
EOF
)"

  curio_ai_generate_stream_to_text "$prompt"
}

curio_ai_check_link_safety() {
  local result_json="$1"
  local link_json="$2"
  local prompt

  prompt="$(cat <<EOF
Evaluate this outbound link for a Curio user.

Selected result:
$result_json

Link:
$link_json

Return strict JSON:
{
  "safe": true,
  "warnings": ["..."],
  "reason": "short explanation"
}

Treat the link as unsafe if it appears suspicious, deceptive, likely to contain immodest imagery, likely to contain bad language, or likely to violate the user's wholesomeness profile.
EOF
)"

  curio_ai_generate_stream_to_text "$prompt" "json"
}
