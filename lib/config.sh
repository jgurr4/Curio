#!/usr/bin/env bash

CURIO_CONFIG_DIR="${CURIO_CONFIG_DIR:-$HOME/.config/curio}"
CURIO_CONFIG_PATH="${CURIO_CONFIG_PATH:-$CURIO_CONFIG_DIR/config.json}"
CURIO_STATE_DIR="${CURIO_STATE_DIR:-$HOME/.local/state/curio}"

curio_write_default_config() {
  mkdir -p "$CURIO_CONFIG_DIR"
  cat >"$CURIO_CONFIG_PATH" <<'EOF'
{
  "wholesomeness": "balanced",
  "results_cap": 100,
  "browser_path": "/bin/firefox",
  "browser_session_duration_seconds": 604800,
  "ai": {
    "base_url": "http://ai.is-a-llama.com:2022",
    "model": "codellama",
    "basic_auth_user": "",
    "basic_auth_password": ""
  },
  "sources": {
    "movies": ["imdb"]
  },
  "filters": {
    "strict": ["porn", "nude", "sex", "gore", "fetish", "vulgar", "explicit"],
    "balanced": ["porn", "nude", "sex", "fetish", "gore"],
    "open": []
  },
  "blocked_shortener_domains": [
    "bit.ly",
    "t.co",
    "tinyurl.com",
    "goo.gl",
    "ow.ly"
  ]
}
EOF
}

curio_init_config_if_missing() {
  if [[ ! -f "$CURIO_CONFIG_PATH" ]]; then
    curio_write_default_config
  fi
}

curio_load_config() {
  curio_init_config_if_missing
  mkdir -p "$CURIO_STATE_DIR"

  CURIO_WHOLESOMENESS="${CURIO_WHOLESOMENESS:-$(jq -r '.wholesomeness // "balanced"' "$CURIO_CONFIG_PATH")}"
  CURIO_RESULTS_CAP="${CURIO_RESULTS_CAP:-$(jq -r '.results_cap // 100' "$CURIO_CONFIG_PATH")}"
  CURIO_BROWSER_PATH="${CURIO_BROWSER_PATH:-$(jq -r '.browser_path // "/bin/firefox"' "$CURIO_CONFIG_PATH")}"
  CURIO_BROWSER_SESSION_DURATION_SECONDS="${CURIO_BROWSER_SESSION_DURATION_SECONDS:-$(jq -r '.browser_session_duration_seconds // 604800' "$CURIO_CONFIG_PATH")}"
  CURIO_AI_BASE_URL="${CURIO_AI_BASE_URL:-$(jq -r '.ai.base_url // "http://ai.is-a-llama.com:2022"' "$CURIO_CONFIG_PATH")}"
  CURIO_AI_MODEL="${CURIO_AI_MODEL:-$(jq -r '.ai.model // "codellama"' "$CURIO_CONFIG_PATH")}"
  CURIO_AI_BASIC_AUTH_USER="${CURIO_AI_BASIC_AUTH_USER:-$(jq -r '.ai.basic_auth_user // ""' "$CURIO_CONFIG_PATH")}"
  CURIO_AI_BASIC_AUTH_PASSWORD="${CURIO_AI_BASIC_AUTH_PASSWORD:-$(jq -r '.ai.basic_auth_password // ""' "$CURIO_CONFIG_PATH")}"

  case "$CURIO_WHOLESOMENESS" in
    strict|balanced|open) ;;
    *)
      curio_die "Invalid wholesomeness level: $CURIO_WHOLESOMENESS"
      ;;
  esac
}

curio_get_filter_terms_json() {
  jq -c --arg level "$CURIO_WHOLESOMENESS" '.filters[$level] // []' "$CURIO_CONFIG_PATH"
}

curio_get_shortener_domains_json() {
  jq -c '.blocked_shortener_domains // []' "$CURIO_CONFIG_PATH"
}
