# photoprism-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [PhotoPrism](https://github.com/photoprism/photoprism).

## What this is

A four-file TOS Docker application archive (`photoprismdocker.tar.gz`) that installs
PhotoPrism on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `photoprismdocker`)
- `photoprismdocker.lang` — 23-language superset (TOS requires 14)
- `photoprismdocker.svg` — application icon (326 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `photoprism/photoprism:261029`

## How it works

| | |
|---|---|
| Container image | `photoprism/photoprism:261029` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8022/` (container port 2342) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/photoprism/storage` → `/Volume1/DockerAppData/photoprismdocker/storage`, `/photoprism/originals` → `/Volume1/DockerAppData/photoprismdocker/originals`, `/photoprism/import` → `/Volume1/DockerAppData/photoprismdocker/import` |
| Logs | `docker logs photoprismdocker` (stdout/stderr) |

Three mounted folders: `storage` holds the index database, settings, cache and the generated admin password; `originals` is the photo/video library the app indexes and serves; `import` is an optional drop folder for bulk imports. Copying `storage` and `originals` is a complete backup.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Admin password bootstrap.** PhotoPrism refuses to create the first admin without `PHOTOPRISM_ADMIN_PASSWORD`. `src/entrypoint.sh` generates a random password once, stores it in `storage/admin-password.txt`, prints it to `docker logs`, and then execs the image's original `/init`. The container still runs as uid 1000.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 2342.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Admin password bootstrap.** The image does not create an admin when `PHOTOPRISM_ADMIN_PASSWORD` is empty. `src/entrypoint.sh` generates a random password once and stores it in the storage volume, then execs the original `/init`.
- **Non-root.** The container runs as `1000:1000`; verified on real hardware that `/init` and the PhotoPrism server work unprivileged.
- **Three volumes, one port.** `storage` + `originals` + `import`; only the web UI port 2342 is published.
- **Health check** probes `/` on 2342; PhotoPrism answers with a 307 redirect to the login page.
- **Fixed image tag**, Docker Hub only, no `privileged`, no host network, no Docker socket.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `storage/index.db` | PhotoPrism index database (photos, faces, labels, albums) | first start | grows with the library | never overwritten; back it up with storage |
| `storage/config/settings.yml` | application settings | first start | small | never overwritten; edit in the UI |
| `storage/admin-password.txt` | generated first administrator password | first start | static | never overwritten; delete only when resetting the admin account |
| `originals` | original photos and videos | by the user | grows with every added photo/video | owned by the user; back it up with storage |
| `import` | optional bulk-import drop folder | first start | transient | clear it after imports |
| `/Volume1/DockerAppData/photoprismdocker/storage` | PhotoPrism application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/photoprismdocker/originals` | PhotoPrism application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/photoprismdocker/import` | PhotoPrism application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/photoprismdocker.tar.gz + .sha256
scripts/build.sh 261029-2   # packaging iteration bump
scripts/build.sh 261029-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/photoprismdocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v261029-1`**, assets `photoprismdocker.tar.gz` +
   `photoprismdocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `photoprismdocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `261029-1` → automated validation → review.

## License / branding

PhotoPrism is distributed by its upstream authors under **AGPL-3.0**. The container image is the official image from Docker Hub (`photoprism/photoprism:261029`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

AI face/object recognition runs on the CPU by default. Large libraries need RAM and CPU; GPU acceleration is not enabled by this package.
The app does not create a photo library. Put your photos into `originals` (or use the import folder); otherwise the library stays empty.
The first admin password is generated on first start. If you lose it, read the file in `storage` or reset it from the container command line; changing it in Settings is recommended.
Plain HTTP on the LAN; do not expose the published port to the internet without a TLS reverse proxy.
One library per instance: the container mounts a single `originals` folder.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
