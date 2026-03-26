#!/bin/bash

SITE="${1:-su}";
PULL_TYPE="${2:-full}";
WORDPRESS_PROJECT_PATH="$HOME/Sites/$SITE";
MIGRATE_PLUGIN="wp-migrate-db-pro";
VERSION_PHP="$(php -r 'echo PHP_VERSION . "\n";')";
VERSION_PHP_ID="$(php -r 'echo PHP_VERSION_ID, "\n";')";

# helper functions
function fail {
    printf '%s\n' "$1" 1>&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

function access_project() {
  echo "Navigating to project directory...";
  sleep 1.5s &>/dev/null;
  [ -d "$WORDPRESS_PROJECT_PATH" ] || fail "Project directory does not exist" 3;
  cd "$WORDPRESS_PROJECT_PATH" || fail "Directory exists but failed to access" 4;
  echo "Successfully accessed $WORDPRESS_PROJECT_PATH";
}

function verify_project() {
  sleep 2s &>/dev/null;
  echo "Checking for core WordPress files...";

  [ -f "$WORDPRESS_PROJECT_PATH/wp-config.php" ] || fail "This is not a wordpress project" 4;
  echo "WordPress check: Done";
}

function define_site_parametres() {
  case "$SITE" in
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
}

function check_php_status() {
  echo "Checking PHP version...";
  sleep 3s;
  echo "Currently running php@$VERSION_PHP";
  echo "PHP check is complete. Proceeding...";
  sleep 3s;
}

function verify_migratedb_pro() {
  echo "Verifying $MIGRATE_PLUGIN status...";

  if ! terminus wp "$pantheon_site_name.$pantheon_env" -- plugin get $MIGRATE_PLUGIN --field=status | grep -q "active-network" &> /dev/null
  then
    echo "WP Migrate DB Pro is not activated";
    echo "Attempting to activate $MIGRATE_PLUGIN";
  fi

  if ! terminus wp "$pantheon_site_name.$pantheon_env" -- plugin activate $MIGRATE_PLUGIN --network
  then
    echo "Could not activate WP Migrate DB Pro";
    echo "Exiting programme...";
    exit 4;
  fi

  echo "Plugin status verification complete. Proceeding...";
}

function retrieve_migration_key() {
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
}

function pull_site() {
  CMD=(wp migratedb pull "https://$pantheon_env-$pantheon_site_name.pantheonsite.io" "$migratedb_key" --exclude-spam);

  #kazi: refactor this switch statement
  case "$PULL_TYPE" in
	  "--single")
	    read -r -p "Which subsite would you like to pull? " sitename;
	    echo "Modifying search & find parametres";
	    migratedb_find_parametres="/code,//$pantheon_env-$pantheon_site_name.pantheonsite.io/$sitename";
	    migratedb_replace_parametres="$HOME/Sites/$SITE,//$SITE.test/$sitename";
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
	    migratedb_replace_parametres="$HOME/Sites/$SITE,//$SITE.test,//$SITE.test,//$SITE.test";
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
}

function deactivate_migratedb_pro() {
  echo "Deactivating WP Migrate DB Pro plugin...";
  terminus wp "$pantheon_site_name.$pantheon_env" -- plugin deactivate $MIGRATE_PLUGIN --network;
}

access_project;
verify_project;
define_site_parametres;
check_php_status;
verify_migratedb_pro;
retrieve_migration_key;
pull_site;
deactivate_migratedb_pro;
