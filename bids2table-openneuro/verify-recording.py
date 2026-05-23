#!/usr/bin/env python3
"""Replay an asciicast through a VT100 emulator (pyte) and verify that the
recorded VisiData session executed as intended.

Two layers of checks:

1. **Error scan** -- walk the cast in fixed-time steps and inspect the
   bottom-right `statuses` popup (where vd shows warnings / exceptions).
   Any new error-shaped line is flagged with the timestamp it first appeared.
   This catches the common failure mode of "the command ran but vd actually
   spat out an error you didn't see".

2. **Checkpoints** -- at named timestamps assert that the screen contains
   expected sheet names / row counts / status-bar text. Catches the case
   where the actions silently did the wrong thing.

Usage:
    verify-recording.py <cast.json> [--checkpoints checkpoints.json]

Exits non-zero if any error is detected or any checkpoint fails.
"""
import argparse
import json
import re
import sys

import pyte


ERROR_PATTERNS = [
    # Python exceptions vd surfaces in the statuses popup
    re.compile(r'\b(Type|Value|Key|Index|Attribute|Runtime|File(NotFound|Exists)|OS|IO)Error\b'),
    re.compile(r'\bException\b'),
    re.compile(r'\bTraceback\b'),
    # vd.warning() / vd.error() messages from our own rc and from vd itself
    re.compile(r'non-numeric'),
    re.compile(r'\binvalid\b', re.IGNORECASE),
    re.compile(r'\bcannot\b', re.IGNORECASE),
    re.compile(r'argument must be'),
    re.compile(r'\bfailed\b', re.IGNORECASE),
    # vd's own diagnostics ("at least one numeric key col necessary for x-axis", etc.)
    re.compile(r'\bnecessary\b', re.IGNORECASE),
    re.compile(r'\bmust be\b', re.IGNORECASE),
    re.compile(r'\bno such\b', re.IGNORECASE),
    re.compile(r'\bcould not\b', re.IGNORECASE),
    # bash error lines that show up if vd exits prematurely and keystrokes hit the shell
    re.compile(r'^bash: '),
    re.compile(r'command not found'),
    re.compile(r'substitution failed'),
]


def screen_text(screen):
    return [row.rstrip() for row in screen.display]


def statuses_popup_lines(rows, height):
    """Extract the contents of vd's `statuses` popup, if visible.

    The popup is drawn with box-drawing characters: a top border
    `lqqq...| statuses |qqqk`, body rows wrapped in `x ... x`, and a
    bottom border `mqqq...qj`. We look for the header and pull lines
    until the bottom border.
    """
    out = []
    in_popup = False
    for r in rows:
        if 'statuses' in r and 'lq' in r:
            in_popup = True
            continue
        if in_popup:
            if 'mq' in r and r.endswith('j'):
                break
            # strip the `x ... x` framing
            m = re.match(r'.*?x\s+(.*?)\s+x\s*$', r)
            if m:
                out.append(m.group(1).strip())
            else:
                out.append(r.strip())
    return out


def scan_for_errors(cast_path, step=1.0):
    """Walk the cast and return list of (timestamp, error_text) for any
    new error-shaped line that appears in the statuses popup or the
    bottom status bar."""
    with open(cast_path) as f:
        hdr = json.loads(next(f))
        lines = f.readlines()
    screen = pyte.Screen(hdr['width'], hdr['height'])
    stream = pyte.Stream(screen)
    seen = set()
    errors = []
    next_check = step
    idx = 0
    last_ts = json.loads(lines[-1])[0]

    while next_check <= last_ts + step:
        # feed events up to next_check
        while idx < len(lines):
            ts, ch, data = json.loads(lines[idx])
            if ts > next_check:
                break
            if ch == 'o':
                stream.feed(data)
            idx += 1

        rows = screen_text(screen)
        popup = statuses_popup_lines(rows, hdr['height'])
        # also look at the bottom 2 rows of the screen (status bar)
        bottom = rows[-2:]
        for src, candidate in [('popup', popup), ('status', bottom)]:
            for line in candidate:
                if not line.strip():
                    continue
                for pat in ERROR_PATTERNS:
                    if pat.search(line):
                        key = (src, line)
                        if key not in seen:
                            seen.add(key)
                            errors.append((next_check, src, line))
                        break
        next_check += step
    return errors


def assert_checkpoints(cast_path, checkpoints):
    """Replay cast and assert that at each (ts, label, needles), every
    needle appears somewhere on the screen."""
    with open(cast_path) as f:
        hdr = json.loads(next(f))
        lines = f.readlines()
    screen = pyte.Screen(hdr['width'], hdr['height'])
    stream = pyte.Stream(screen)
    idx = 0
    fails = []
    for ts, label, needles in checkpoints:
        # feed up to ts
        while idx < len(lines):
            ev_ts, ch, data = json.loads(lines[idx])
            if ev_ts > ts:
                break
            if ch == 'o':
                stream.feed(data)
            idx += 1
        rows = screen_text(screen)
        missing = [n for n in needles if not any(n in r for r in rows)]
        if missing:
            fails.append((ts, label, missing, rows[-3:]))
            print(f'  FAIL @ t={ts}s ({label}): missing {missing}')
            for r in rows[-3:]:
                if r.strip():
                    print(f'    > {r[:140]}')
        else:
            short = rows[-1][:120]
            print(f'  PASS @ t={ts}s ({label})  status: {short!r}')
    return fails


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('cast')
    ap.add_argument('--checkpoints', help='JSON file with [[ts, label, [needles]], ...]')
    ap.add_argument('--step', type=float, default=1.0, help='seconds between error-scan samples')
    args = ap.parse_args()

    with open(args.cast) as f:
        hdr = json.loads(next(f))
        last_ts = 0
        for line in f:
            try:
                last_ts = json.loads(line)[0]
            except Exception:
                pass
    print(f'cast: width={hdr["width"]} height={hdr["height"]} wall={last_ts:.1f}s')

    # 1. error scan
    print('\n[error scan]')
    errors = scan_for_errors(args.cast, step=args.step)
    if errors:
        for ts, src, line in errors:
            print(f'  ERROR @ t={ts:.0f}s [{src}]  {line}')
    else:
        print('  no errors detected')

    # 2. checkpoints
    fails = []
    if args.checkpoints:
        with open(args.checkpoints) as f:
            checkpoints = [tuple(c) for c in json.load(f)]
        print('\n[checkpoints]')
        fails = assert_checkpoints(args.cast, checkpoints)

    print()
    if errors or fails:
        print(f'verification FAILED: {len(errors)} errors, {len(fails)} checkpoint failures')
        return 1
    print('verification passed')
    return 0


if __name__ == '__main__':
    sys.exit(main())
