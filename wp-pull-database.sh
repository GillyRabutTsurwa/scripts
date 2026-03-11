#!/bin/bash

WORDPRESS_PROJECT_PATH="$HOME/Sites/$1";
MIGRATE_PLUGIN="wp-migrate-db-pro";

echo "Moving to WordPress directory...";
sleep 3s;

cd "$WORDPRESS_PROJECT_PATH" || exit;

if [ -f "$WORDPRESS_PROJECT_PATH/wp-config.php" ]
then
  echo "WordPress check: Done";
else
  echo "This is not a wordpress project";
  exit 1;
fi

case "$1" in
	"su")
	   pantheon_site_name="su-edu";
	   pantheon_env="live";
     site_url="su.edu";
     www_site_url="www.$site_url";
	   ;;
	"ssmt")
	   pantheon_site_name="su-ssmtva";
	   pantheon_env="live";
     site_url="ssmtva.org";
     www_site_url="www.$site_url";
	   ;;
	*)
	   echo "Ce site n'existe pas";
	   exit 3;
	   ;;
esac

echo "Setting migration parametres...";

VERSION_PHP="$(php -r 'echo PHP_VERSION . "\n";')";
VERSION_PHP_ID="$(php -r 'echo PHP_VERSION_ID, "\n";')";

echo "Checking PHP version...";
sleep 3s;
echo "Currently running php@$VERSION_PHP";
echo "PHP check is complete. Proceeding...";
sleep 3s;

echo "Verifying $MIGRATE_PLUGIN status...";

if ! terminus wp "$pantheon_site_name.$pantheon_env" -- plugin get $MIGRATE_PLUGIN --field=status | grep -q "active-network" &> /dev/null
then
  echo "WP Migrate DB Pro is not activated";
  echo "Attempting to activate $MIGRATE_PLUGIN";
  exit 3;
fi

if ! terminus wp "$pantheon_site_name.$pantheon_env" -- plugin activate $MIGRATE_PLUGIN --network
then
  echo "Could not activate WP Migrate DB Pro";
  echo "Exiting programme...";
  exit 4;
fi

echo "Plugin status verification complete. Proceeding...";

echo "Retrieving migration key...";
sleep 3s;

if [[ $VERSION_PHP_ID -lt 80400 ]]
then
	migratedb_key="$(terminus_unstable wp $pantheon_site_name.$pantheon_env -- migratedb setting get connection-key)";
else
	migratedb_key="$(terminus wp $pantheon_site_name.$pantheon_env -- migratedb setting get connection-key)";
fi

sleep 3s;

if [ -z "$migratedb_key" ]
then
	echo "Error: could not retrieve the production site's migration key";
	exit 2;
fi

CMD=(wp migratedb pull "https://$pantheon_env-$pantheon_site_name.pantheonsite.io" "$migratedb_key" --exclude-spam);

case "$2" in
	"--single")
	   read -r -p "Which subsite would you like to pull? " sitename;
	   echo "Modifying search & find parametres";
	   migratedb_find_parametres="/code,//$pantheon_env-$pantheon_site_name.pantheonsite.io/$sitename";
	   migratedb_replace_parametres="$HOME/Sites/$1,//$1.test/$sitename";
	   subsite_url="$pantheon_env-$pantheon_site_name.pantheonsite.io/$sitename";
	   echo "$subsite_url";
	   CMD+=(--find="$migratedb_find_parametres" --replace="$migratedb_replace_parametres" --subsite="$subsite_url");
	   echo "Pulling $sitename";
	   echo "$pantheon_env-$pantheon_site_name.pantheonsite.io/$sitename";
	   if "${CMD[@]}";
	   then
	    echo "Successfully pulled $sitename site";
	   else
	    echo "Failed to pull $sitename site";
		exit 4;
	   fi
	   ;;
	"--full"|"")
	   echo "Modifying search & find parametres";
	   migratedb_find_parametres="/code,//$pantheon_env-$pantheon_site_name.pantheonsite.io,//$site_url,//$www_site_url";
	   migratedb_replace_parametres="$HOME/Sites/$1,//$1.test,//$1.test,//$1.test";
	   echo "Performing a pull of the entire site (all subsites)";
	   CMD+=(--find="$migratedb_find_parametres" --replace="$migratedb_replace_parametres");
	   if "${CMD[@]}"
	   then
      echo "Full pull of all sites in $pantheon_env-$pantheon_site_name.pantheonsite.io";
	   else
	    echo "Pull of all sites in $pantheon_env-$pantheon_site_name.pantheonsite.io has failed";
	   fi
	   ;;
	*)
	   echo "Inserted invalid arguement...";
	   echo "Stopping script execution";
	   exit 5;
	   ;;
esac

echo "Deactivating WP Migrate DB Pro plugin...";
terminus wp "$pantheon_site_name.$pantheon_env" -- plugin deactivate $MIGRATE_PLUGIN --network;

