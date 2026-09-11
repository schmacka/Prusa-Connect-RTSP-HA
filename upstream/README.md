# Reviewed upstream snapshot

This directory is a **read-only record**, not code that runs. It holds a
byte-exact copy of the files we track from
[Knopersikcuo/Prusa-Connect-RTSP](https://github.com/Knopersikcuo/Prusa-Connect-RTSP)
as of the revision recorded in [`UPSTREAM_REV`](UPSTREAM_REV):

| file | purpose |
|---|---|
| `main.py` | upstream's application, for diffing only — **not** the add-on's source |
| `requirements.txt` | upstream's dependency pins, for diffing only |
| `UPSTREAM_REV` | the upstream commit this snapshot was taken from |

Nothing in the container is built from these files. The add-on ships
`prusa_connect_rtsp/`.

## Why the snapshot exists

`prusa_connect_rtsp/main.py` started as a copy of upstream's `main.py` and has
since diverged substantially (489 lines locally against upstream's 350). It
carries fixes that do not exist upstream:

| local fix | why | shipped in |
|---|---|---|
| `CAP_FFMPEG` | forces OpenCV's FFMPEG backend so RTSP works in Alpine containers | v1.3.6 |
| `CONNECT_RETRY_DELAY` | retries the camera connection at startup instead of exiting | v1.3.3 / v1.3.4 |
| `OFFLINE_BACKOFF_THRESHOLD` | backs off exponentially when Prusa Connect rejects frames because the printer is offline | v1.3.5 |

The `Sync Upstream` workflow used to `curl` upstream's `main.py` directly over
`prusa_connect_rtsp/main.py`. There was no merge and no conflict detection, so
every one of those fixes would have been silently reverted the first time the
workflow managed to open a pull request. (Its pull request step had always
failed, which is the only reason the repo escaped the regression.)

Keeping a pristine snapshot means upstream changes can still be *seen* — as a
diff between two upstream revisions — without any automation writing to the
add-on's own source.

## How a sync happens now

1. [`.github/workflows/sync-upstream.yml`](../.github/workflows/sync-upstream.yml)
   runs daily and calls
   [`scripts/check-upstream-drift.sh`](../scripts/check-upstream-drift.sh).
2. If upstream still matches this snapshot, the run ends quietly.
3. If upstream has moved, the workflow opens a pull request that updates
   **only this directory**, with the upstream-to-upstream diff in the body. The
   workflow and the script each refuse to continue if anything under
   `prusa_connect_rtsp/` was modified.
4. A human reads that diff and decides, change by change, what is worth porting
   into `prusa_connect_rtsp/`, by hand, preserving the local fixes above.
5. Merging the pull request records "this upstream revision has been reviewed".
   It does not mean the changes were adopted.

## Checking drift locally

```bash
./scripts/check-upstream-drift.sh            # report only; exit 1 means upstream moved
./scripts/check-upstream-drift.sh --help     # offline dry runs, snapshot updates
```
