#!/bin/zsh --no-rcs

readonly cache="${alfred_workflow_data}"
: ${cached:=0}
: ${go_to_find_folder:=0}

if [[ $cached -ne 1 ]]; then
	echo -n "{\"rerun\":2,\"items\":[{\"title\":\"Building UTType Cache\",\"valid\":false,\"subtitle\":\"This will only take a few seconds...\"}]}"
elif [[ $go_to_find_folder -eq 1 ]]; then
    osascript -e 'tell application id "com.runningwithcrayons.Alfred" to run trigger "find_folder" in workflow "com.zeitlings.mkfile"'
else
	local query=$1
	query="${query//\\/\\\\}" # escape backslashes
	query="${query//\"/\\\"}" # escape double quotes
	query="${query//:/-}"     # replace colons with hyphens
	local cmp=("${(@s/./)query}")
	local icon="\"icon\":{\"path\":\"images/icons/unk.png\"}"
	local dotfile=0

	# sans extension dotfile handling: ..gitignore
	if [[ "$query" == ..* ]]; then
	    query=""
		d_ext="${cmp[-1]}"
		dotfile=1
		icon="\"icon\":{\"path\":\"images/icons/dot.png\"}"
	elif [[ "$#cmp[@]" -gt 1 ]]; then
    	query="${(j:.:)cmp[1,-2]}"
        d_ext="${cmp[-1]}"
		[[ -z "$query" ]] && query="untitled"
	elif [[ ! -n $query ]]; then
		query="untitled"
	fi

	if [[ -f "${cache}/proto.$d_ext" ]]; then
		readonly UTI=$(mdls -name kMDItemContentType -raw "${cache}/proto.$d_ext")
		icon="\"icon\":{\"type\":\"filetype\",\"path\":\"$UTI\"}"
	fi

	# Autocomplete
	subtitle="Create in '$location:r:t'"
	if [[ $dotfile -eq 1 ]]; then
	   subtitle="Create dotfile in '$location:r:t'"
	fi
	autocomplete="$query.$d_ext" # title+extension

	# guard that some extension has been entered
	if [[ -n "${cmp[-1]}" && "$autosuggest" -eq 1 ]]; then
		local extensions=("${(f)$(< ./src/assets/extensions.txt)}")

		# filter on entered file extension
		if [[ -n $d_ext ]]; then
			set -A filtered
			for extension in "${extensions[@]}"; do
				local n="$extension:t"
				[[ -f $extension ]] || n=$extension:t
				if [[ $n = $d_ext* && $n != $d_ext ]]; then
					subtitle+="  |  ⇥  ${query}.$extension"
					autocomplete="${query}.$extension"
					if [[ $dotfile -eq 1 ]]; then
					   autocomplete="..$extension"
					fi
					break
				fi
			done
		fi
	fi

	response="{\"items\":[{\"title\":\"$query.$d_ext\",\"arg\":\"$location$query\",\"subtitle\":\"$subtitle\",$icon,\"autocomplete\":\"$autocomplete\",\"mods\":{\"cmd\":{\"subtitle\":\"${location/$HOME/~}\"},\"cmd+shift\":{\"subtitle\":\"Create with Clipboard Contents\",\"variables\":{\"insert_pb\":1}},\"alt+shift\":{\"subtitle\":\"Create without Clipboard Contents\",\"variables\":{\"insert_pb\":0}}}}],\"variables\":{\"d_ext\":\"$d_ext\"}}"
	printf "%s" $response
fi
