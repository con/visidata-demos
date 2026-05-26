#!/bin/bash
#
# Screencaster demo: Exploring the OpenNeuro BIDS Index with VisiData
#
# Showcases bids2table over OpenNeuro -- hiding empty BIDS columns, discovering
# which datasets carry a given task/modality via frequency analysis, and
# plotting summary stats.
#
# For the screencast we use demo-subset.parquet -- a ~22k-row proportional
# 1% sample of the full archive (with a 100-row floor per datatype so rare
# modalities stay visible). Proportional sampling means the headline
# `Shift+F` on datatype shows realistic ratios (func > eeg > anat > ...),
# not the artificial equal-count plateau you'd get from a flat per-datatype
# cap. The full tool-b2t2_archive-openneuro_date-20260521.parquet
# (2,065,565 rows) works identically; the walkthrough in README.md is
# written for the full file.
#
# Terminal size: 144x34 (adjust cast2asciinema width/height or resize terminal)
#
# Prerequisites:
#   - VisiData installed with pyarrow + pandas
#   - screencaster (https://github.com/datalad/screencaster) in PATH
#   - demo-subset.parquet in working directory
#   - dot_visidatarc with custom commands
#
# Usage:
#   cd /path/to/bids2table-openneuro
#   cast2asciinema demo-bids2table.sh output/
#
# Notes for stable recording:
#   - `kspace` (defined below) sends Escape first, then Space -- this clears
#     any half-typed command palette / leftover prompt before opening a fresh
#     one, even if vd is mid-operation.
#   - Sleeps after Shift+F, hide-degenerate-cols, and the Canvas plot are
#     deliberately long; vd's command palette autocomplete and column scans
#     are noticeably slow on parquet files.

# wrapper: Escape (clear any stale prompt) then Space (open command palette)
kspace() {
    key Escape; sleep 0.4
    key space;  sleep 0.4
}

# wrapper: run a longname (Space + type + Return) with reset
klong() {
    kspace
    type "$1"; sleep 0.6
    key Return; sleep 0.4
}

# wrapper: demo-say a message
ksay() {
    klong "demo-say"
    type "$1"; sleep 0.6
    key Return
    sleep 4
}

say "Exploring the OpenNeuro BIDS Index with VisiData -- a bids2table index of every file across OpenNeuro, stratified-sampled to 94k rows so the recording stays responsive"

run "cd $PWD"
run "export TERM=xterm-256color"

# --- Launch VisiData ---
say "Loading demo-subset.parquet ..."
type "vd --config dot_visidatarc demo-subset.parquet"
key Return
sleep 8

# === Phase 1: orientation + hide-degenerate ===
ksay "22k BIDS files (1% stratified sample of OpenNeuro) * 43 BIDS-entity columns -- most cells are empty"
ksay "Sweep BIDS columns that no archived OpenNeuro dataset populates (tpl, cohort, sample, nuc, stain, chunk, scale)"

klong "hide-degenerate-cols"
sleep 8

ksay "Several BIDS extensions are unused across OpenNeuro -- those columns are now hidden"

# === Phase 2: frequency analysis on datatype ===
klong "go-col-regex"
type "^datatype$"; sleep 0.6
key Return
sleep 3

ksay "Frequency analysis on datatype (Shift+F) -- modality breakdown"

key Escape; sleep 0.4
key shift+f
sleep 8
# Sheet stack: [main, freq-datatype]  (depth 2)

ksay "func dominates, eeg close behind, then anat, figures, dwi, fmap, ieeg, meg, perf (figures+derivatives are bids2table folder labels, not BIDS modalities)"

ksay "Look at the histogram column on the right -- vd's built-in inline ASCII bar plot, no extra command needed"

ksay "vd also has a Canvas plot at . (plot-column) -- requires a numeric key col, see README for setup"

# === Phase 3: drill into eeg subset and hide degenerate ===
ksay "Drill into eeg files -- search for ^eeg$ then Enter"

key Escape; sleep 0.4
key slash; sleep 0.5
type "^eeg$"; sleep 0.4
key Return
sleep 2

key Return
sleep 5
# Sheet stack: [main, freq-datatype, eeg-subset]  (depth 3)

ksay "EEG subset -- now collapse the BIDS columns not used by EEG"

klong "hide-degenerate-cols"
sleep 8

ksay "Most of the 43 columns drop away -- EEG uses only ~8 BIDS entities"

# Back out to main: eeg-subset -> freq-datatype -> main
key Escape; sleep 0.4; key q; sleep 1.5
key Escape; sleep 0.4; key q; sleep 1.5
# Sheet stack: [main]  (depth 1)

# === Phase 4: frequency on task, drill into rest, freq on dataset ===
klong "go-col-regex"
type "^task$"; sleep 0.6
key Return
sleep 3

ksay "Frequency on task -- thousands of distinct tasks across OpenNeuro"

key Escape; sleep 0.4
key shift+f
sleep 8
# Sheet stack: [main, freq-task]  (depth 2)

ksay "Top task: rest -- which OpenNeuro datasets carry resting-state data?"

key Escape; sleep 0.4
key slash; sleep 0.5
type "^rest$"; sleep 0.4
key Return
sleep 2

key Return
sleep 5
# Sheet stack: [main, freq-task, rest-subset]  (depth 3)

klong "go-col-regex"
type "^dataset$"; sleep 0.6
key Return
sleep 3

key Escape; sleep 0.4
key shift+f
sleep 8
# Sheet stack: [main, freq-task, rest-subset, freq-dataset-of-rest]  (depth 4)

ksay "Datasets ranked by # of resting-state files -- ds######, sorted, with inline ASCII histogram"

# === Phase 5: open-openneuro on the top dataset ===
ksay "open-openneuro -- jump to https://openneuro.org/datasets/<ds######>"

klong "open-openneuro"
sleep 4

# === Exit VisiData: 4 q's to pop all sheets ===
key Escape; sleep 0.4; key q; sleep 1.5
key Escape; sleep 0.4; key q; sleep 1.5
key Escape; sleep 0.4; key q; sleep 1.5
key Escape; sleep 0.4; key q; sleep 1.5

say "VisiData on bids2table -- discover what's in OpenNeuro from the terminal:"
say "  hide-degenerate-cols -- collapse 43 BIDS columns to the ones in use"
say "  Shift+F -- frequency analysis on any column (datatype, task, suffix, dataset)"
say "  Enter on a freq row -- drill into the matching subset"
say "  histogram column on freq sheets -- inline ASCII bars, no extra command"
say "  open-openneuro -- open the dataset page in the browser"
