#!/bin/bash

SITE="$1";
ENVIRONMENT="$2";

# helper functions
function fail {
    printf "%s\n" "$1" 1>&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

function script_exec_check() {
  echo "verifying script parametres...";
  for current_arguement in "$@"
  do
    [ -z "$current_arguement" ] && fail "action non permise" 3;
  done
  echo "parametres check finished. proceeding...";
}

function prevent_cloning_to_live() {
  if [[ "$ENVIRONMENT" == "live" ]]
  then
    echo "you aren't allowed to clone to a live site";
    echo "exiting programme";
    exit 2;
  fi
}

function clone() {
  read -rp "Enter the official domain of the source site: " domain;
  terminus site:list --field=name --format=list | grep --quiet --line-regexp "$SITE" || fail "$SITE nonexistante. essayez de nouveau" 3;
  terminus backup:create "$SITE.$ENVIRONMENT" --keep-for=90 || fail "could not properly backup site. will not proceed with cloning" 4;
  terminus env:clone-content "$SITE.live" "$ENVIRONMENT" --from-url="$domain" --to-url="$ENVIRONMENT-$SITE.pantheonsite.io" || fail "cloning of $SITE.$ENVIRONMENT failed" 5;

  echo "successful cloning of $SITE.$ENVIRONMENT";
}

script_exec_check "$1" "$2";
prevent_cloning_to_live;
clone;
