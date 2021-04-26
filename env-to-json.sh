#!/usr/bin/env bash
set -euo pipefail

if [ -e "$HOME/projects/config.json" ]; then
	echo "config file exists at $HOME/projects/config.json - ignoring environment variables!"
else
	echo "saving environment variables to config file at $HOME/projects/config.json"
	jq -n '{
      "downloader": env.DOWNLOADER,
      "http_password": env.HTTP_PASSWORD,
      "http_username": env.HTTP_USERNAME,
      "selected_project": env.SELECTED_PROJECT,
      "shared:rsync_threads": env.SHARED_RSYNC_THREADS,
      "warrior_id": env.WARRIOR_ID,
      "concurrent_items": env.CONCURRENT_ITEMS
    } | with_entries( select(.value != null) )' >"$HOME/projects/config.json"
fi
