# Curio Presentation Workspace

This workspace keeps presentation content in your project repo. `vendor/` is intentionally git-ignored.

## Structure

- `decks/curio/index.html`: first Curio product deck.
- `decks/modules/*.md`: reusable module slides.
- `decks/templates/deck-template.html`: generator base template.
- `scripts/generate-deck.mjs`: create new decks from modules.
- `scripts/setup-vendor-reveal.sh`: optional local setup for `vendor/reveal.js`.

## Run the deck (Docker, recommended)

```bash
cd /home/jared/repos/curio
docker build -t curio-decks .
docker run --rm -p 4173:80 --name curio-decks curio-decks
```

Docker build automatically downloads a pinned `reveal.js` version and injects it into `/vendor/reveal.js` inside the image, so no committed vendor assets are required.

Open `http://127.0.0.1:4173/decks/curio/` (include trailing slash).
Shortcut URL: `http://127.0.0.1:4173/present/curio/`.

To stop:

```bash
Ctrl+C
```

## Run the deck (host fallback)

```bash
cd /home/jared/repos/curio
npm run vendor:setup
npm run serve
```

`npm run vendor:setup` downloads reveal.js runtime assets (`dist/`, `plugin/`, `LICENSE`) into `vendor/reveal.js` for local non-Docker serving.

To pin or test a different reveal.js version:

```bash
sh scripts/setup-vendor-reveal.sh 5.2.1
docker build --build-arg REVEAL_VERSION=5.2.1 -t curio-decks .
```

## Generate a new deck

```bash
cd /home/jared/repos/curio
npm run deck:new -- q2-plan "Q2 Plan" "project-idea,sre-workflow,database-review"
```

Open `http://127.0.0.1:4173/decks/q2-plan/`.
