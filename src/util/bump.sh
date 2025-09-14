#!/bin/bash
if [[ "$HTTPSH_VERSION" != "${cfg[init_version]}" ]]; then
	sed -i '/cfg\[init_version\]=/d' config/master.sh
	echo "cfg[init_version]=$HTTPSH_VERSION" >> "config/master.sh"
	echo "Version bumped. I hope you checked for breaking changes!"
else
	echo "All good! :3"
fi
