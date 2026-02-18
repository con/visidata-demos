#!/bin/bash
#
# Screencaster demo: Exploring a Research Group's Knowledge Graph with VisiData
#
# Showcases custom VisiData commands for linked-data (CURIE) exploration
# on a 1339-record psychoinformatics research group knowledge graph.
#
# Terminal size: 144x34 (adjust cast2asciinema width/height or resize terminal)
#
# Prerequisites:
#   - VisiData installed
#   - screencaster (https://github.com/datalad/screencaster) in PATH
#   - data.jsonl and unreleased.context.jsonld in working directory
#   - dot_visidatarc with custom commands
#
# Usage:
#   cd /path/to/psychoinformatics-1
#   cast2asciinema demo-linkeddata.sh output/

say "Exploring a Research Group's Knowledge Graph with VisiData custom commands decode linked-data identifiers (CURIEs) using a JSON-LD context to expand compact prefixes to full URLs"

# cast_bash.rc cd's to SCREENCAST_HOME (/demo by default);
# we need the project directory where data files live
run "cd $PWD"
run "export TERM=xterm-256color"
run "export VISIDATA_JSONLD_CONTEXT=\$PWD/unreleased.context.jsonld"

# --- Launch VisiData ---
say "Loading 1339 records from data.jsonl ..."
type "visidata --config dot_visidatarc data.jsonl"
key Return
sleep 4

# --- Orientation ---
# Sheet stack: [main]  (depth 1)
key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "1339 records, 29 columns -- a sparse linked-data export"; key Return
sleep 3

# --- Navigate to schema_type column ---
key space; sleep 0.5
type "go-col-regex"; sleep 1; key Return; sleep 0.5
type "schema_type"; key Return
sleep 2

# --- Frequency analysis on schema_type ---
key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "Frequency analysis on schema_type (Shift+F)"; key Return
sleep 2

key shift+f
sleep 3
# Sheet stack: [main, frequency]  (depth 2)

# --- Filter to Rule rows (726 license definitions) ---
key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "726 Rule rows -- license/data-use definitions"; key Return
sleep 3

key slash; sleep 0.5
type "Rule"; key Return
sleep 2

# Dive into the matching frequency row
key Return
sleep 3
# Sheet stack: [main, frequency, rules-filtered]  (depth 3)

# --- Hide degenerate columns ---
key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "21 of 29 columns are empty for Rules -- hiding them"; key Return
sleep 2

key space; sleep 0.5
type "hide-degenerate-cols"; sleep 1; key Return
sleep 3

# --- Navigate to pid, search for CC-BY-4.0 ---
key space; sleep 0.5
type "go-col-regex"; sleep 1; key Return; sleep 0.5
type "pid"; key Return
sleep 2

key slash; sleep 0.5
type "CC-BY-4.0"; key Return
sleep 2

# --- describe-curie on CC-BY-4.0 ---
key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "Resolving spdxlic:CC-BY-4.0 via SPDX API"; key Return
sleep 2

key space; sleep 0.5
type "describe-curie"; sleep 1; key Return
sleep 6
# Sheet stack: [main, frequency, rules-filtered, curie-result]  (depth 4)

key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "name, OSI/FSF status, see-also links -- all from the CURIE"; key Return
sleep 4

# --- Back out to main data ---
# 3 q's: curie-result -> rules-filtered -> frequency -> main
key q; sleep 1
key q; sleep 1
key q; sleep 1
# Sheet stack: [main]  (depth 1)

# --- Filter to Person rows ---
key space; sleep 0.5
type "go-col-regex"; sleep 1; key Return; sleep 0.5
type "schema_type"; key Return
sleep 2

key shift+f
sleep 3
# Sheet stack: [main, frequency]  (depth 2)

key slash; sleep 0.5
type "Person"; key Return
sleep 1

key Return
sleep 3
# Sheet stack: [main, frequency, person-filtered]  (depth 3)

# --- Hide degenerate columns for Person view ---
key space; sleep 0.5
type "hide-degenerate-cols"; sleep 1; key Return
sleep 3

key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "29 researchers with names, ORCIDs, affiliations"; key Return
sleep 3

# --- Exit VisiData ---
# 3 q's: person-filtered -> frequency -> main -> exit
key q; sleep 1
key q; sleep 1
key q; sleep 1

say "Custom VisiData commands for linked data:"
say "  hide-degenerate-cols -- hide columns where all values are empty"
say "  describe-curie -- resolve a CURIE to metadata via API"
say "  open-curie -- open expanded CURIE URL in the browser"
say "CURIEs resolved: SPDX licenses, OBO ontologies, ROR, ORCID, DOI"
