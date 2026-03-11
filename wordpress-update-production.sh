#!/bin/bash
parent_remote_server="live";
child_remote_server="$1";
wordpress_version_parent="$(terminus wp su-edu."$parent_remote_server" -- core version --url=www.su.edu)";
wordpress_version_child="$(terminus wp su-edu."$child_remote_server" -- core version)";

function update_wordpress() {
	if [[ "$1" == "local" ]]
	then
		wp core update --version="$wordpress_version_parent";
	elif [[ "$1" == "test" || "$1" == "dev" ]]
	then
       		terminus wp su-edu."$1" -- core update --version="$wordpress_version_parent";
	else
		echo "This is not an applicable wordpress server";
		echo "Stopping Script execution";
		exit 5;
	fi
}

if [ $# -eq 0 ]
then
        echo "Error: remote server not specified";
	echo "Your options are \"dev\" and \"test\"";
        echo "Stopping script execution";
        exit 1;
fi

if [[ "$1" == "$parent_remote_server" ]]
then
	echo "You are not allowed to change the wordpress version in this server";
	exit 2;
fi

if [[ "$1" == "local" ]]
then
	cd "$HOME/Sites/su" || exit;
	child_remote_server="$HOME/Sites/su";
	wordpress_version_child="$(wp core version)";
fi

echo "The current WP version for the $parent_remote_server site is $wordpress_version_parent";
echo "The current WP Version for the $child_remote_server is $wordpress_version_child";

if [[ "$wordpress_version_child" != "$wordpress_version_parent" ]]
then
	echo "wordpress version in $child_remote_server site is different from the version in the $parent_remote_server site";
        echo "Child site version: $wordpress_version_child";
        echo "Parent site version: $wordpress_version_parent";
	echo "Updating wordpress version in $child_remote_server";
	update_wordpress "$1";
else
	echo "wordpress versions are the same in the main and child sites";
	echo "No update needed";
fi
