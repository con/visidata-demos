# Exploring the OpenNeuro BIDS Index with VisiData

A walkthrough for neuroimagers: use [VisiData](https://www.visidata.org/) to
explore a [bids2table](https://childmindresearch.github.io/bids2table/) index
of every file currently in [OpenNeuro](https://openneuro.org), find which
datasets contain the modalities or tasks you care about, and produce summary
plots — all from a terminal, on a 2-million-row table, in a few keystrokes.

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
- **plot-freq-png** — render a matplotlib bar chart of the current sheet's
  top-N rows (uses the `count` column produced by `Shift+F`) and `xdg-open`
  it. Better for screenshots than VisiData's built-in `.` plotter.
- **demo-say** — show narration in the status bar (for screencaster demos).

## Walkthrough

> Install (uvx pulls everything fresh into a temp env):
>
>     uvx --from 'visidata' --with pyarrow --with pandas --with matplotlib \
>       vd --config dot_visidatarc tool-b2t2_archive-openneuro_date-20260521.parquet

It takes a few seconds to load the ~2M rows.

### 1. Tame the column count: hide empty columns

Out of the gate, many columns (`tpl`, `cohort`, `nuc`, `voi`, `stain`, ...)
are empty for the typical row — they exist for niche BIDS extensions.

    Space  hide-degenerate-cols   Enter

You should drop from 43 visible columns to ~15. Pressing `Shift+V` on a column
toggles wide view; `_` autosizes; `gv` re-shows everything.

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

From any frequency sheet:

    Space  plot-freq-png   Enter         # default: top 20

Writes `/tmp/visidata-plot.png` and opens it. Great for slides and for
cross-checking that the freq counts make sense.

VisiData's built-in `.` works too on a numeric column — a quick in-terminal
plot without leaving the keyboard.

## Recording the demo

Requires [screencaster](https://github.com/datalad/screencaster) and its
dependencies (`xdotool`, `xterm`, `asciinema`).

    cast2asciinema demo-bids2table.sh output/
    asciinema play output/demo-bids2table.json
