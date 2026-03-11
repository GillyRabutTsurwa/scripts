#!/bin/bash

wordpress_path="$HOME/Sites/${1:-ssmt}"
log_file="$wordpress_path/logs/plugin-updates.txt"
git_commit_title="Plugin Updates"
github_remote="origin"
git_branch="${2:-master}"

# helper functions
function fail {
    printf '%s\n' "$1" 1>&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

function access_project() {
  echo "Navigating to project directory...";
  sleep 1.5s &>/dev/null;
  [ -d "$wordpress_path" ] || fail "Project directory does not exist" 3;
  cd "$wordpress_path" || fail "Directory exists but failed to access" 4;
  echo "Successfully accessed $wordpress_path";
}

function verify_project() {
  echo "Checking for git in the project...";
  [ -d "$wordpress_path/.git" ] || fail "This is not a git project" 4;
  echo "Git check: Done";

  sleep 2s &>/dev/null;
  echo "Checking for core WordPress files...";

  [ -f "$wordpress_path/wp-config.php" ] || fail "This is not a wordpress project" 4;
  echo "WordPress check: Done";
 }

function git_branch_switch() {
  if [[ $(git branch --show-current) != "$git_branch" ]]
  then
    echo "You are currently not in the $git_branch branch";
    echo "Switching to $git_branch";
    git checkout "$git_branch";
  else
    echo "Aready at the $git_branch branch";
  fi
}

function convert_list_to_array() {
  if ! command -v mapfile
  then
    echo "The mapfile command is not installed in this machine";
    echo "Will attempt to proceed without it..."
    plugins=();
    while IFS= read -r current_plugin
    do
      plugins+=("$current_plugin");
    done < <(wp plugin list --update=available --field=name | grep --invert-match "$wordpress_path/manual-updateable-plugins.txt")
  fi
  mapfile -t plugins < <(wp plugin list --update=available --field=name | grep --invert-match "$wordpress_path/manual-updateable-plugins.txt");
}

function pre_update() {
  if [[ ! -d logs || ! -f $log_file ]]
  then
    mkdir logs && touch "logs/$log_file";
    if ! grep -q "logs" .gitignore
    then
      echo "logs" >>"$wordpress_path/.gitignore";
    fi
  fi
  # Prepending Git commit title for log file
  echo "$git_commit_title" >>"$log_file";
  echo >>"$log_file";
}

function update_plugins() {
  local plugins_count;
  plugins_count="$(wp plugin list --update=available --format=count)";
  if [[ "$plugins_count" -eq 0 ]]
  then
    echo "All plugins are up to date";
    truncate -s 0 "$log_file";
    exit 3;
  fi

  echo "There are $plugins_count plugins that can be updated";
  # looping over indeces in the array due to ${!plugins[@]} and not the values themselves. can still access the values.
  for index in "${!plugins[@]}"
  do
    #wp plugin update "${plugins[index]}";
    # if [[ $? -eq 0 ]]; then
    if output="$(wp plugin update "${plugins[index]}")"
    then
      changelog_data_file="readme.txt";
      version_updated=$(wp plugin get "${plugins[index]}" --field=version);
      echo "$output";
      echo "- ${plugins[index]} has been successfully updated to version $version_updated" >>"$log_file";
      if [[ -f "$wordpress_path/wp-content/plugins/${plugins[index]}/$changelog_data_file" ]]
      then
        git diff "$wordpress_path/wp-content/plugins/${plugins[index]}/$changelog_data_file" | grep '^+' | sed '/^+++/d' | sed 's/^+//' >>"$log_file";
        echo >>"$log_file;"
      fi
    else
      echo "${plugins[index]} failed up to update. Consult your WordPress admin panel to address this";
    fi
  done
  echo "Updating plugins complete";
}

function commit_and_push() {
  echo "Checking for updates to add to git";
  sleep 3s &>/dev/null;
  git add wp-content/plugins/ --all; # this will add everything in the wp-content/plugins directory recursively
  if [[ $(git diff --staged --exit-code) ]]
  then
    echo "Initiating commit for plugin updates";
    git commit --file "$log_file";
    git push "$github_remote" "$git_branch" --force;
  else
    echo "There are no plugin changes to commit";
  fi
}

function cleanup() {
  echo "If not plugins were updated try installing the remaining ones manually at your discretion";
  echo "Note that plugins that require licence keys to be updated must be updated manually";
  echo "Updating process complete";

  # cleanup of log file
  truncate -s 0 "$log_file";
}

#[ -z "$1" ]  || [ -z "$2" ] && fail "One or both arguements are empty";
access_project;
verify_project;
git_branch_switch;
convert_list_to_array;
pre_update;
update_plugins;
commit_and_push;
cleanup;

# praise Yahuah my Elohim
# may He bless and sancitfy this code
# in the Name of Yahusha
