# Curio

Curio is a terminal-first content discovery tool. The current MVP implements the first end-to-end slice for:

```bash
./curio discover movies --tags "civil war, inspirational"
```

That flow currently does:
- fetch movie candidates from IMDb first
- fall back to DuckDuckGo site search against IMDb if needed
- apply hard-coded wholesomeness filters
- send remaining candidates to your Ollama-compatible Curio AI endpoint for curation
- store results in a local session
- allow follow-up `ask` and guarded `open` commands in the same terminal session

## Requirements

- `bash`
- `curl`
- `jq`
- `python3`
- Linux browser path configured in Curio config

## First Run

Initialize config:

```bash
./curio init
```

This creates:

```text
~/.config/curio/config.json
~/.local/state/curio/session.json
```

Default config includes:
- wholesomeness: `balanced`
- results cap: `100`
- browser path: `/bin/firefox`
- browser session duration: `604800` seconds
- AI base URL: `http://ai.is-a-llama.com:2022`
- AI model: `qwen3:30b-a3b-q4`

Set your reverse-proxy basic auth credentials in `~/.config/curio/config.json`:

```json
"ai": {
  "base_url": "http://ai.is-a-llama.com:2022",
  "model": "codellama",
  "basic_auth_user": "your-user",
  "basic_auth_password": "your-password"
}
```

## Usage

One-shot entry:

```bash
./curio discover movies --tags "civil war, inspirational, leadership"
```

After that, Curio drops into an interactive session. Available commands:

```bash
discover movies --tags "classic westerns"
ask 1 "Is this suitable for a family movie night?"
open 1 A
show
help
quit
```

Direct commands outside the REPL also work:

```bash
./curio ask 1 "What is this movie about?"
./curio open 1 A
./curio show
```

## How the Movie MVP Works

1. `providers/movies.sh` fetches raw candidates.
2. Hard filters remove candidates containing blocked terms for the current wholesomeness level.
3. `lib/ai.sh` sends the filtered list to Ollama `/api/generate` using streaming responses.
4. Curio expects structured JSON back from the model and stores curated results in session state.
5. `ask` re-queries the AI about a selected result.
6. `open` runs hard checks plus an AI safety review before opening the browser.

## Current Limitations

- Only `movies` is implemented right now.
- Browser content-block rule revocation is not automated yet.
- IMDb fetching is best-effort and may need tuning if their response shape changes.
- Link safety uses a mix of hard rules and AI judgment; it is not yet backed by a persistent user blacklist.
- Session state is local and single-user.

## Repository Layout

- [curio](curio/curio): main Bash entrypoint
- [lib/config.sh](curio/lib/config.sh): config loading and defaults
- [lib/ai.sh](curio/lib/ai.sh): Ollama-compatible AI integration
- [lib/browser.sh](curio/lib/browser.sh): guarded link opening
- [providers/movies.sh](curio/providers/movies.sh): movie candidate fetch and hard filtering
- [decks/curio/index.html](curio/decks/curio/index.html): project presentation deck

## Presentation Deck

The reveal.js deck is still available:

```bash
docker build -t curio-decks .
docker run --rm -p 4173:80 --name curio-decks curio-decks
```

Then open:

```text
http://127.0.0.1:4173/decks/curio/
```
