#!/bin/bash

SITE="$1";
ENVIRONMENT="$2";
LOG_FILE_PATH="$HOME/logs/$SITE/$ENVIRONMENT";
LOG_FILE="$LOG_FILE_PATH/updateable-plugins.txt";

# helper functions
function fail {
    printf '%s\n' "$1" 1>&2 ## Send message to stderr.
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

function log_file_check() {
  if [ ! -f "$LOG_FILE" ]
  then
    echo "Log file missing";
    echo "Creating log file...";
    if [ ! -d "$LOG_FILE_PATH" ]
    then
      mkdir -p "$LOG_FILE_PATH";
    fi
    touch "$LOG_FILE";
  fi
}

function tool_check() {
  if ! command -v terminus &> /dev/null
  then
    echo "you must install terminus";
    exit 1;
  fi
}

function list_plugins() {
 if ! $(which terminus) wp "$SITE"."$ENVIRONMENT" -- plugin list --update=available >> "$LOG_FILE"
 then
    echo "failed listing plugins";
    exit 2;
 fi
  echo "successfully listed plugins in $LOG_FILE";
}

script_exec_check "$1" "$2";
log_file_check;
tool_check;
list_plugins;
