#!/bin/bash
#
# Screencaster demo: Exploring the OpenNeuro BIDS Index with VisiData
#
# Showcases bids2table over the entire OpenNeuro archive (2M+ files, 43
# BIDS-entity columns) -- hiding empty columns, discovering which datasets
# carry a given task/modality via frequency analysis, and plotting summary
# stats.
#
# Terminal size: 144x34 (adjust cast2asciinema width/height or resize terminal)
#
# Prerequisites:
#   - VisiData installed with pyarrow + pandas + matplotlib
#       (e.g. uvx --from visidata --with pyarrow --with pandas --with matplotlib vd ...)
#   - screencaster (https://github.com/datalad/screencaster) in PATH
#   - tool-b2t2_archive-openneuro_date-20260521.parquet in working directory
#   - dot_visidatarc with custom commands
#
# Usage:
#   cd /path/to/bids2table-openneuro
#   cast2asciinema demo-bids2table.sh output/

say "Exploring the OpenNeuro BIDS Index with VisiData -- 2 million BIDS files across the entire OpenNeuro archive, indexed with bids2table into a single Parquet table"

# cast_bash.rc cd's to SCREENCAST_HOME (/demo by default);
# we need the project directory where data files live
run "cd $PWD"
run "export TERM=xterm-256color"

# --- Launch VisiData ---
say "Loading 2,065,565 rows from the bids2table Parquet ..."
type "vd --config dot_visidatarc tool-b2t2_archive-openneuro_date-20260521.parquet"
key Return
sleep 18

# --- Orientation ---
# Sheet stack: [main]  (depth 1)
key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "2,065,565 files * 43 BIDS-entity columns -- most cells are empty"; key Return
sleep 4

# --- Hide degenerate columns on the full table ---
key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "Sweep entirely-empty BIDS columns (tpl, cohort, sample, nuc, stain, chunk, scale)"; key Return
sleep 4

key space; sleep 0.5
type "hide-degenerate-cols"; sleep 1; key Return
sleep 16

key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "43 columns -> 36 -- those 7 BIDS extensions are unused across OpenNeuro"; key Return
sleep 4

# --- Frequency analysis on datatype ---
key space; sleep 0.5
type "go-col-regex"; sleep 1; key Return; sleep 0.5
type "datatype"; key Return
sleep 2

key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "Frequency analysis on datatype (Shift+F) -- modality breakdown across OpenNeuro"; key Return
sleep 4

key shift+f
sleep 12
# Sheet stack: [main, freq-datatype]  (depth 2)

key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "func dominates, then eeg, anat, dwi, fmap, ieeg, meg, perf, ..."; key Return
sleep 5

# --- Plot the datatype frequency ---
key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "Render a matplotlib bar chart PNG of the top datatypes"; key Return
sleep 3

key space; sleep 0.5
type "plot-freq-png"; sleep 1; key Return
sleep 1
type "15"; key Return
sleep 5

# --- Dive into eeg subset and hide degenerate ---
key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "Drill into eeg files -- Enter on the eeg frequency row"; key Return
sleep 4

key slash; sleep 0.5
type "^eeg$"; key Return
sleep 1

key Return
sleep 6
# Sheet stack: [main, freq-datatype, eeg-subset]  (depth 3)

key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "EEG subset (586k rows) -- which BIDS entities are actually populated?"; key Return
sleep 4

key space; sleep 0.5
type "hide-degenerate-cols"; sleep 1; key Return
sleep 12

key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "Most of the 43 columns drop away -- EEG uses ~8 BIDS entities"; key Return
sleep 5

# --- Back out to main ---
# 2 q's: eeg-subset -> freq-datatype -> main
key q; sleep 1
key q; sleep 1
# Sheet stack: [main]  (depth 1)

# --- Frequency analysis on task ---
key space; sleep 0.5
type "go-col-regex"; sleep 1; key Return; sleep 0.5
type "^task$"; key Return
sleep 2

key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "Frequency on task -- 2,857 distinct tasks across OpenNeuro"; key Return
sleep 4

key shift+f
sleep 14
# Sheet stack: [main, freq-task]  (depth 2)

key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "Top task: rest -- which OpenNeuro datasets have resting-state data?"; key Return
sleep 5

# --- Dive into rest, then frequency on dataset ---
key slash; sleep 0.5
type "^rest$"; key Return
sleep 1

key Return
sleep 6
# Sheet stack: [main, freq-task, rest-subset]  (depth 3)

key space; sleep 0.5
type "go-col-regex"; sleep 1; key Return; sleep 0.5
type "^dataset$"; key Return
sleep 2

key shift+f
sleep 10
# Sheet stack: [main, freq-task, rest-subset, freq-dataset-of-rest]  (depth 4)

key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "Datasets ranked by # of resting-state files -- ds######, sorted"; key Return
sleep 5

# --- Plot the rest-by-dataset chart ---
key space; sleep 0.5
type "plot-freq-png"; sleep 1; key Return
sleep 1
type "20"; key Return
sleep 5

# --- Jump to the OpenNeuro page for the top dataset ---
key space; sleep 0.5
type "demo-say"; sleep 1; key Return; sleep 0.5
type "open-openneuro -- jump to https://openneuro.org/datasets/<ds######>"; key Return
sleep 4

key space; sleep 0.5
type "open-openneuro"; sleep 1; key Return
sleep 5

# --- Exit VisiData ---
# 4 q's: freq-dataset-of-rest -> rest-subset -> freq-task -> main -> exit
key q; sleep 1
key q; sleep 1
key q; sleep 1
key q; sleep 1

say "VisiData on bids2table -- discover what's in OpenNeuro from the terminal:"
say "  hide-degenerate-cols -- collapse 43 BIDS columns to the ones in use"
say "  Shift+F -- frequency analysis on any column (datatype, task, suffix, dataset)"
say "  Enter on a freq row -- drill into the matching subset"
say "  plot-freq-png -- matplotlib bar chart of the top-N rows"
say "  open-openneuro -- open the dataset page in the browser"
