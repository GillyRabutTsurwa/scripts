#!/bin/bash

CURRENT_DATE=$(date +%d-%m-%Y);
REMOTE_HOST=$(echo "$2" | cut -d ':' -f 1);
REMOTE_DIR_PATH=$(echo "$2" | cut -d ':' -f 2);

if [ $# -lt 2 ]
then
  echo "Usage: backup.sh <source_directory> <target_directory> <test_option: test>";
  echo "This script needs at least 2 arguements";
  exit 1;
fi

if ! command -v rsync &> /dev/null
then
  echo "This script requires rsync to be installed";
  echo "Please use your distribution's package manager to install";
  exit 2;
fi

# create log file
if [ ! -d "$1/logs" ]
then
  mkdir -p "$1/logs" && touch "$1/logs/backup_$CURRENT_DATE.log";
fi

if [[ "$2" == *":"* ]]
then
  ssh "$REMOTE_HOST" <<"EOF"
		if [ ! -d "$2" ]
      then
        mkdir -p "$REMOTE_DIR_PATH";
    fi
EOF
  RSYNC_OPTIONS="--archive --verbose --delete --backup --backup-dir=$REMOTE_DIR_PATH/backup/$CURRENT_DATE --exclude=logs";
else
  if [ ! -d "$2" ]
  then
    echo "Making directory";
    mkdir -p "$2";
  fi
  RSYNC_OPTIONS="--archive --verbose --delete --backup --backup-dir=$2/backup/$CURRENT_DATE --exclude=logs";
fi

if [ ! -f /tmp/sauvegarder_excludes.txt ]
then
  echo "Excludes list file not found";
  echo "Attempting to create one";
  touch /tmp/sauvegarder_excludes.txt;
fi

echo "Finding node_modules directories...";
echo "node_modules" 1> /tmp/sauvegarder_excludes.txt;
echo "Ignoring the node_modules directories";
RSYNC_OPTIONS+=" --exclude-from=/tmp/sauvegarder_excludes.txt";

if [[ -n "$3" && "$3" == "--test" ]]
then
  echo "$3";
  RSYNC_OPTIONS+=" --dry-run";
fi

echo "$RSYNC_OPTIONS";
$(which rsync) "$1" "$2" "$RSYNC_OPTIONS" >>"$1/logs/backup_$CURRENT_DATE.log";

truncate -s 0 /tmp/sauvegarder_excludes.txt;

# Attention
# ce code ci-dessous:
# ./backup.sh text-files backup
# ne fonctionne pas pareillement que celui-ci:
# ./backup.sh text-files/ backup
# le premier code va copier le dossier "text-files" et tout ses contenants dans notre dossier backup
# alors que le deuxieme va copier seulement le contentants du dossier "text-files". Le dossier lui-meme ne sera pas transfere
# utiliser l'un ou l'autre selon vos besoins

# merci Yahuah, mon Seigneur
# may you sanctify this piece of code, and may it glorify you
