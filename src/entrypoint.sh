#!/bin/sh
# PhotoPrism needs PHOTOPRISM_ADMIN_PASSWORD to create the first admin account;
# without it the web UI starts but there is no way to log in. Generate a random
# password once, keep it in the mounted storage volume, print it to the log and
# then hand over to the image's original /init.
set -u

log() { printf '[photoprism] %s\n' "$*"; }

STORAGE=/photoprism/storage
PWFILE="$STORAGE/admin-password.txt"

mkdir -p "$STORAGE" /photoprism/originals /photoprism/import 2>/dev/null || true

if [ -z "${PHOTOPRISM_ADMIN_PASSWORD-}" ]; then
    if [ -s "$PWFILE" ]; then
        PHOTOPRISM_ADMIN_PASSWORD=$(cat "$PWFILE")
    else
        PHOTOPRISM_ADMIN_PASSWORD=$(od -An -N18 -tx1 /dev/urandom | tr -d ' \n')
        umask 077
        printf '%s\n' "$PHOTOPRISM_ADMIN_PASSWORD" > "$PWFILE"
        chmod 600 "$PWFILE"
        log "generated initial admin password for user admin: $PHOTOPRISM_ADMIN_PASSWORD"
    fi
    export PHOTOPRISM_ADMIN_PASSWORD
fi
export PHOTOPRISM_ADMIN_USER="${PHOTOPRISM_ADMIN_USER-admin}"

log "starting PhotoPrism as uid $(id -u), gid $(id -g)"
exec /init
