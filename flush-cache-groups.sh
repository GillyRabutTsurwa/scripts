#!/bin/bash

CURRENT_DATE=$(date +%d-%m-%Y);
ENVIRONMENT="${1:-test}";
LOG_FILE="/tmp/cache-flush-$CURRENT_DATE-$ENVIRONMENT";
CMD_TERMINUS=(terminus connection:info su-edu."$ENVIRONMENT");
REDIS_HOST="$("${CMD_TERMINUS[@]}" --fields=redis_url --format=string | cut -d "@" -f 2 | cut -d ":" -f 1)";
REDIS_PORT="$("${CMD_TERMINUS[@]}" --fields=redis_port --format=string)";
REDIS_PASSWORD="$("${CMD_TERMINUS[@]}" --fields=redis_password --format=string)";
CMD_REDIS=(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD")
CACHE_GROUP_NAME="${2:-$("${CMD_REDIS[@]}" --scan --pattern 'ocppantheon:1*' | cut -d ":" -f3 | sort -u | grep "tribe-events")}";

mapfile -t CACHED_KEYS < <("${CMD_REDIS[@]}" --scan --pattern "*1:$CACHE_GROUP_NAME*");

if [ ! -f "$LOG_FILE" ]
then
  echo "Logfile does not exist";
  echo "Creating logfile @ $LOG_FILE..." > "$LOG_FILE";
  touch "$LOG_FILE";
fi

echo "Attempting removal of ${#CACHED_KEYS[@]} piece(s) of $CACHE_GROUP_NAME from the $ENVIRONMENT cache" >> "$LOG_FILE";
printf '%s\n' "${CACHED_KEYS[@]}" >> "$LOG_FILE";

sleep 5s;
terminus wp su-edu."$ENVIRONMENT" -- cache flush-group "$CACHE_GROUP_NAME" >> "$LOG_FILE";

if [ ${#CACHED_KEYS[@]} -le 1 ]
then
  echo "flushing the $CACHE_GROUP_NAME data was successful" >> "$LOG_FILE";
else
  echo "flushing was not successful... try again later" >> "$LOG_FILE";
fi
