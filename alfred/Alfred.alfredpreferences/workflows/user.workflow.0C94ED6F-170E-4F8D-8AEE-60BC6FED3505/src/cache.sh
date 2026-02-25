#!/bin/zsh

readonly ext_f="${alfred_preferences}/workflows/${alfred_workflow_uid}/src/assets/extensions.txt"
readonly data="${alfred_workflow_data}"
readonly extensions=("${(f)$(cat $ext_f)}")

[[ -d $data ]] || mkdir -p $data

for e in "$extensions[@]"; do
	touch "$data/proto.$e"
done

cat <<EOF | osascript
	tell application id "com.runningwithcrayons.Alfred"
	 	set theWorkflow to "${alfred_workflow_bundleid}"
	 	set envvarCached to "cached"
 		set theValue to "1"
	 	set configuration envvarCached to value theValue in workflow theWorkflow
	 	reload workflow theWorkflow
	 end tell
EOF
