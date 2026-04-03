# Curio Presentation Workspace

This workspace keeps presentation content in your project repo and treats `reveal.js` as a vendored dependency in `vendor/reveal.js`.

## Structure

- `decks/curio/index.html`: first Curio product deck.
- `decks/modules/*.md`: reusable module slides.
- `decks/templates/deck-template.html`: generator base template.
- `scripts/generate-deck.mjs`: create new decks from modules.
- `vendor/reveal.js`: runtime assets copied from open-source reveal.js.

## Run the deck (Docker, recommended)

```bash
cd /home/jared/repos/curio
docker build -t curio-decks .
docker run --rm -p 4173:80 --name curio-decks curio-decks
```

Open `http://127.0.0.1:4173/decks/curio/` (include trailing slash).
Shortcut URL: `http://127.0.0.1:4173/present/curio/`.

To stop:

```bash
Ctrl+C
```

## Run the deck (host fallback)

```bash
cd /home/jared/repos/curio
npm run serve
```

## Generate a new deck

```bash
cd /home/jared/repos/curio
npm run deck:new -- q2-plan "Q2 Plan" "project-idea,sre-workflow,database-review"
```

Open `http://127.0.0.1:4173/decks/q2-plan/`.
