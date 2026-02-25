# Create a temporary filename with a timestamp
temp_file="clip_content_$(date +%s).txt"

# Save clipboard content to the temporary file
#pbpaste > "$temp_file"
echo "$MYVAR" > "$temp_file"

# Convert the saved content to bib format and save the result
anystyle --stdout -f bib parse $temp_file | pbcopy

# Delete the temporary file
rm "$temp_file"

