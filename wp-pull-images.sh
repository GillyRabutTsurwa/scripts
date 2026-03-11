#!/bin/bash

SITE="$1";
ENVIRONMENT="$2";
SERVER_USERNAME="$(terminus connection:info "$SITE"."$ENVIRONMENT" --fields=sftp_username --format=string)";
SERVER_HOST="$(terminus connection:info "$SITE"."$ENVIRONMENT" --fields=sftp_host --format=string)";
SERVER_PATH="code/wp-content/uploads";
SRC="$SERVER_USERNAME@$SERVER_HOST:$SERVER_PATH";
DEST="$HOME/Sites/$3/wp-content";

function check_server_parametres() {
  if [ -z "$1" ]
  then
    echo "$1 does not exist";
    exit 1;
  fi
}

function verify_destination() {
  if [ ! -d "$DEST" ]
  then
    echo "Cannot find $DEST";
    exit 3;
  fi
}

function transfer_images() {
  if rsync --archive --verbose --delete --copy-links --size-only --checksum --compress --progress --rsh="ssh" "$SRC" "$DEST";
  then
	  echo "Image file transfer failed";
  else
  	echo "Successfully transfered images";
  fi
}

check_server_parametres "$SERVER_USERNAME";
check_server_parametres "$SERVER_HOST";
verify_destination;
transfer_images;

