# Exploring the OpenNeuro BIDS Index with VisiData

A walkthrough for neuroimagers: use [VisiData](https://www.visidata.org/) to
explore a [bids2table](https://childmindresearch.github.io/bids2table/) index
of every file currently in [OpenNeuro](https://openneuro.org), find which
datasets contain the modalities or tasks you care about, and produce summary
plots — all from a terminal, on a 2-million-row table, in a few keystrokes.

[![demo](https://asciinema.org/a/s40ivIIgieWO1lSN.svg)](https://asciinema.org/a/s40ivIIgieWO1lSN)

The screencast above uses `demo-subset.parquet` — a 94k-row stratified sample
that keeps modality and dataset diversity but stays responsive enough to
record reliably. All commands work identically on the full 2,065,565-row
file used in the walkthrough below.

## The data

`tool-b2t2_archive-openneuro_date-20260521.parquet` is one row per BIDS file
across the entire OpenNeuro archive snapshotted on 2026-05-21:

- **2,065,565 rows** (files)
- **43 columns**, one per BIDS entity (`sub`, `ses`, `task`, `run`, `acq`,
  `echo`, `space`, `desc`, ...) plus `dataset`, `datatype`, `suffix`, `ext`,
  `extra_entities`, `root`, `path`
- Most columns are **sparse**: each row only uses the entities that apply
  to its modality (e.g. an EEG file has `task` but no `echo`/`flip`).

It was produced with

    b2t2 index -o openneuro.parquet -j 8 --use-threads s3://openneuro.org/ds*

and renamed following BIDS-like naming. A TSV mirror
(`tool-b2t2_archive-openneuro_date-20260521.tsv`) is shipped alongside for
tools that don't yet read Parquet — incl. opening directly from URL:

    vd https://www.oneukrainian.com/tmp/tool-b2t2_archive-openneuro_date-20260521.tsv

(Parquet-over-HTTPS is tracked in https://github.com/saulpw/visidata/issues/3097.)

## Custom VisiData commands

Defined in [`dot_visidatarc`](dot_visidatarc), invoked via VisiData's command
palette (`Space`):

- **hide-degenerate-cols** — hide columns where every value is empty
  (None/`""`/`[]`/`{}`). Sweeps 43 → ~5-10 once you've filtered to a single
  modality.
- **hide-mostly-degenerate-cols** — same, but ≥95% empty (keeps rare-but-present
  entities visible).
- **open-openneuro** — opens `https://openneuro.org/datasets/<ds######>` in a
  browser for the dataset ID under the cursor (works on `dataset` or `root`
  cells).
- **demo-say** — show narration in the status bar (for screencaster demos).

For visualisation we lean on VisiData's built-ins: the Frequency Sheet ships
an inline ASCII `histogram` column, and `.` (`plot-column`) on a numeric
column opens a Canvas plot. No matplotlib, no PNG — terminal demo, terminal
output.

## Walkthrough

> Install (uvx pulls everything fresh into a temp env):
>
>     uvx --from 'visidata' --with pyarrow --with pandas \
>       vd --config dot_visidatarc tool-b2t2_archive-openneuro_date-20260521.parquet

It takes a few seconds to load the ~2M rows.

### 1. Tame the column count: hide empty columns

Out of 43 BIDS-entity columns, seven (`tpl`, `cohort`, `sample`, `nuc`,
`stain`, `chunk`, `scale`) are **completely empty** across all of OpenNeuro —
they exist for BIDS extensions no archived dataset uses. Another 20 are
populated in less than 5% of files (`tracksys`, `voi`, `ce`, `trc`, `mod`,
`flip`, `inv`, `mt`, `part`, `proc`, `hemi`, `space`, `split`, `recording`,
`atlas`, `seg`, `res`, `den`, `label`, `rec`).

    Space  hide-degenerate-cols   Enter         # drops 7 fully-empty cols
    Space  hide-mostly-degenerate-cols  Enter   # drops 27 cols (<5% populated)

(Pressing `Shift+V` on a column toggles wide view; `_` autosizes; `gv`
re-shows everything.) The real impact of `hide-degenerate-cols` comes
*after* drilling into a single modality — see §4.

### 2. What modalities are in OpenNeuro? Frequency on `datatype`

Navigate to the `datatype` column (`Space go-col-regex` → `datatype`) and hit
`Shift+F` for a frequency table:

| datatype    | count   |
|-------------|--------:|
| func        | 708,068 |
| eeg         | 586,643 |
| anat        | 175,717 |
| figures     | 110,275 |
| dwi         | 104,707 |
| fmap        |  93,870 |
| ieeg        |  57,149 |
| meg         |  40,735 |
| perf        |  36,906 |
| beh         |  33,921 |
| swi         |  24,265 |
| derivatives |  13,206 |
| nirs        |  10,928 |
| pet         |   5,011 |
| motion      |   3,746 |

(see `Space plot-freq-png` for a labelled bar-chart PNG of the above.)

### 3. Discover datasets with data of interest: drill into `task`

Press `q` back to the main sheet, navigate to `task`, `Shift+F`. The top
tasks in OpenNeuro are `rest`, `EC` / `EO` (eyes-closed/open), `social`,
`alignvideo`, `nback`, `seizure`, ... (out of **2,857 unique tasks**).

To find every dataset that contains a resting-state run:

1. `/` then `^rest$` to position the cursor on the `rest` row
2. `Enter` to dive into the matching subset (every file with `task=rest`)
3. Navigate to `dataset`, `Shift+F` → now you see the **list of OpenNeuro
   datasets containing resting-state data, sorted by file count**.
4. On a `dataset` row, `Space open-openneuro` jumps to the public page.

The same pattern works for any entity: which datasets have `suffix=dwi`?
Which have `space=MNI152NLin2009cAsym`? Which acquired `tracksys=*` motion
data?

### 4. Per-modality column coverage

To see *which BIDS entities are actually used* by a given modality, filter to
that modality then hide-degenerate:

1. From the main sheet, navigate to `datatype`, `Shift+F`, `Enter` on `eeg`
2. `Space hide-degenerate-cols`

For EEG you'll see ~8 columns survive (`dataset`, `sub`, `ses`, `task`,
`acq`, `run`, `suffix`, `ext`, `path`) — the rest of the 43-column BIDS
schema is irrelevant to EEG. Repeat with `func`, `dwi`, etc. to learn the
shape of each modality's metadata.

### 5. Plot summary stats

Frequency sheets already include an inline ASCII `histogram` column that
draws horizontal bars next to each bin — visible without any extra
command. For a fuller chart, press `.` (`plot-column`) on the `count`
column to open a Canvas plot in the terminal; `q` returns to the freq
sheet.

## Recording the demo

Requires [screencaster](https://github.com/datalad/screencaster) and its
dependencies (`xdotool`, `xterm`, `asciinema`).

    cast2asciinema demo-bids2table.sh output/
    asciinema play output/demo-bids2table.json

To upload to asciinema.org and get a shareable badge URL:

    asciinema upload output/demo-bids2table.json

## Verifying a recording

`xdotool`-driven recordings are fragile: keystrokes can land while vd is
mid-operation, error popups can absorb input, and you only find out the
demo went sideways once a viewer points at the badge and says "this isn't
what the README describes". To catch that here:

    pip install pyte
    ./verify-recording.py output/demo-bids2table.json \
        --checkpoints demo-checkpoints.json

[`verify-recording.py`](verify-recording.py) replays the cast through a
headless VT100 emulator and does two things:

1. **Error scan** — samples the screen every second and flags any line in
   vd's bottom-right `statuses` popup (or the status bar) that looks like
   a warning / exception / "must be" / "command not found" / `bash:
   substitution failed` / Python tracebacks. Catches the case where vd
   *ran your command but quietly threw a warning* you'd otherwise miss.
2. **Checkpoint assertions** — at named timestamps in
   [`demo-checkpoints.json`](demo-checkpoints.json), asserts that the
   screen contains the sheet name / row count / status-bar text you
   expect. Catches the case where keystrokes silently landed on the
   wrong sheet.

A clean recording yields:

    [error scan]
      no errors detected
    [checkpoints]
      PASS @ t=25s (vd loaded, main sheet)
      PASS @ t=55s (after hide-degenerate-cols)
      ...
    verification passed
