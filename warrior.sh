#!/usr/bin/env bash

set -euo pipefail
export DOCKER=1

if [ "$1" == "run-warrior3" ]; then
	env-to-json.sh

	exec run-warrior3 \
		--projects-dir "$HOME/projects" \
		--data-dir "$HOME/data" \
		--warrior-hq "http://warriorhq.archiveteam.org" \
		--port "8001" \
		--real-shutdown
fi

exec "$@"
