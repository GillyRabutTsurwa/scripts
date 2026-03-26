#!/bin/bash

SITE="${1:-'su-edu'}";
ENVIRONMENT="${2:-live}";
SERVER_USERNAME="$(terminus connection:info "$SITE"."$ENVIRONMENT" --fields=sftp_username --format=string)";
SERVER_HOST="$(terminus connection:info "$SITE"."$ENVIRONMENT" --fields=sftp_host --format=string)";
SERVER_PATH="code/wp-content/uploads";
SRC="$SERVER_USERNAME@$SERVER_HOST:$SERVER_PATH";
DEST="$HOME/Sites/${3:-su}/wp-content";

function fail {
    printf '%s\n' "$1" 1>&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

function check_server_parametres() {
  [ -z "$1" ] || fail "$1 does not exist" 2;
}

function verify_destination() {
  [ ! -d "$DEST" ] || fail "Cannot find $DEST" 3;
}

function transfer_images() {
  if rsync --archive --verbose --delete --copy-links --size-only --checksum --compress --progress --rsh="ssh" "$SRC" "$DEST";
  then
	  echo "Image file transfer failed";
  else
  	echo "Successfully transfered images from $DEST to $SRC";
  fi
}

check_server_parametres "$SERVER_USERNAME";
check_server_parametres "$SERVER_HOST";
verify_destination;
transfer_images;

