# Robustness patches for `dump-things-pyclient`

Proposed upstream fixes for
<https://hub.psychoinformatics.de/orinoco/dump-things-pyclient>, which is what
`make fetch` uses. They address the connection timeouts that kept aborting
`dtc get-records` against a busy `pool.psychoinformatics.de`.

## Provenance

Generated against the **sources shipped in the `dump_things_pyclient-0.3.0`
wheel on PyPI**, not against a clone -- `hub.psychoinformatics.de` is not
reachable from where these were prepared. The wheel is pure Python and ships
every `.py` file of the package, so the tree matches the 0.3.0 release
exactly; but the baseline commit is a reconstruction, and the patches only
touch two files:

    dump_things_pyclient/communicate.py
    dump_things_pyclient/commands/dtc.py

If the upstream branch has moved past 0.3.0 they may need `git am -3` or a
rebase.

## Applying

    git am 0001-*.patch 0002-*.patch     # keeps the two commits separate

or, for a single unrecorded change:

    git apply dtc-robustness.combined.diff

## What is in them

**0001 -- Retry failed requests and apply timeouts by default.** `dtc` made its
requests with no timeout and no retry adapter; `requests` defaults to
`max_retries=0`, so one refused or slow connection ended the whole operation,
and urllib3 reported it as "Max retries exceeded" even though nothing had been
retried. `get_session()` now returns a session with an `HTTPAdapter` carrying a
`Retry` policy (connection errors, read errors, 429/500/502/503/504, exponential
backoff, `Retry-After` honoured, `POST` excluded via urllib3's default
`allowed_methods`) and a default timeout on every request.

Every `dtc` sub-command calls `get_session()` with no arguments, so a
`configure()` hook sets the defaults process-wide and no sub-command needed
changing. `dtc` exposes it as four global options with matching environment
variables:

    --retries          DTC_RETRIES           (default 5, 0 restores old behaviour)
    --retry-backoff    DTC_RETRY_BACKOFF     (default 1.0 s)
    --connect-timeout  DTC_CONNECT_TIMEOUT   (default 30 s)
    --read-timeout     DTC_READ_TIMEOUT      (default 300 s)

Requests made without an explicit session used to bypass all of this via the
module-level `requests.get`/`post`/`delete`; they now go through a temporary
session that is closed after use. `server()` built its request by hand and now
uses `_get_from_url()` like every other endpoint wrapper.

**0002 -- Stop `get_paginated()` from looping forever past the last page.**
The loop ended on `page == min(last_page, total_pages)`, which is never true if
it starts beyond the end of the result set. `dtc get-records --first-page 20` on
a 14-page collection asks for page 21, 22, ... indefinitely. Changed to `>=`.

## Verification

Against a local mock serving the same fastapi-pagination JSON shape as
dump-things-service, with failures injected on 5 of 14 pages (503, 504, 502 and
mid-dump connection resets):

| | result |
|---|---|
| 0.3.0 as released | exit 1 after 200 of 1339 records |
| patched | exit 0, all 1339 records |
| patched, `--retries 0` | exit 1 after 200 records (i.e. old behaviour restored) |

Also checked: output byte-identical to an unpatched run against a healthy
server; `--read-timeout` aborts and retries a stalled response; `POST` is not
retried; `--first-page` past the end returns immediately instead of looping
(0.3.0 was still spinning when killed after 10 s).

The package's own test suite gives the same result before and after: 4 passed,
12 errors -- the errors are all `tests/assets/pyclient_testschema.yaml`, which
the wheel does not ship, so they cannot run from a wheel-based tree at all.

## Not addressed

`dtc get-records --stats` is accepted and then silently ignored -- `get_records()`
never looks at the flag (`read-pages --stats` does work). Left alone here since
it is unrelated to robustness.

Note also that page size cannot be raised as a workaround: the CLI clamps
`--page-size` to 1..100, and dump-things-service paginates with
fastapi-pagination's stock `Params` (`size = Query(50, ge=1, le=100)`), so a
larger page is rejected with 422 server-side.
