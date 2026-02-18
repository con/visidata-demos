# Exploring Linked Data with VisiData

Custom VisiData commands for exploring linked-data knowledge graphs — decoding
CURIEs (Compact URIs), resolving identifiers via APIs, and hiding sparse columns.

[![demo](https://asciinema.org/a/1y7iNWAsSbwpHnlI.svg)](https://asciinema.org/a/1y7iNWAsSbwpHnlI)

## Custom Commands

Defined in `dot_visidatarc`, invoked via VisiData's command palette (`Space`):

- **hide-degenerate-cols** — hide columns where all values are empty (None/[]/{}/"")
- **hide-mostly-degenerate-cols** — hide columns where 95%+ values are empty
- **describe-curie** — expand a CURIE to a full URL and fetch metadata via API (SPDX, ORCID, ROR, DOI, OBO, etc.)
- **open-curie** — expand a CURIE and open the URL in a browser
- **demo-say** — display narration text in the status bar (for screencaster demos)

CURIE expansion uses a JSON-LD context file to map prefixes to base URLs.

## Usage

```bash
export VISIDATA_JSONLD_CONTEXT=$PWD/unreleased.context.jsonld
visidata --config dot_visidatarc data.jsonl
```

## Data

`data.jsonl` contains 1339 records from a psychoinformatics research group
knowledge graph — license rules, publications, people, organizations, grants,
and more, each identified by CURIEs like `spdxlic:CC-BY-4.0` or `ror:02nv7yv05`.

## Recording the Demo

Requires [screencaster](https://github.com/datalad/screencaster) and its
dependencies (xdotool, xterm, asciinema).

```bash
SCREENCAST_HOME=/tmp/demo cast2asciinema demo-linkeddata.sh output/
asciinema play output/demo-linkeddata.json
```
