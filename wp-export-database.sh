#!/bin/bash
current_date=$(date +%d-%m-%Y);

case $1 in
        "su")
           pantheon_site_name="su-edu";
           pantheon_env="gtsurwa-dev";
           ;;
        "ssmt")
           pantheon_site_name="su-ssmtva";
           pantheon_env="dev";
           ;;
        *)
           echo "Ce site n'existe pas";
           exit 3;
           ;;
esac

echo "Setting migration parametres";

migratedb_find_parametres="/code,//$pantheon_env-$pantheon_site_name.pantheonsite.io,//www.su.edu";
migratedb_replace_parametres="~/Sites/$1,//$1.test,//$1.test";

sleep 3s &> /dev/null;
echo "Initiating export";

terminus wp $pantheon_site_name.$pantheon_env -- migratedb export "$HOME/$1_$current_date.sql" \
--find="$migratedb_find_parametres" \
--replace="$migratedb_replace_parametres" \
--exclude-spam \

if [[ $? -eq 0 ]]
then
	echo "Export successful";
else
	echo "Export failed, consult your wordpress, verify your parametre values and try again";
fi
