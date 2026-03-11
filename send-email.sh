#!/bin/bash

RECEPIENT="$1";
SUBJECT="$2";
BODY_FILE="$3";

cat <<EOF | sendmail -t
To: "$RECEPIENT
Subject: "$SUBJECT"
$(cat "$BODY_FILE")
EOF
