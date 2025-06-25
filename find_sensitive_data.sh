#!/bin/bash
#
# Description: This script reads a list of .js file URLs from a file,
#              downloads each file, and searches for potentially sensitive
#              information (keys, tokens) and API endpoints using more
#              targeted regular expressions. It prints the scanned URL
#              and then either the matching lines or "No hit".
#
# Usage: ./find_sensitive_data_regex_v2.sh <list_of_js_files.txt>
#
#        Where list_of_js_files.txt contains one URL per line.
#
# Author: Gemini
#

# Check if the input file is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <list_of_js_files_v2.sh>"
  exit 1
fi

# Input file containing list of .js file URLs
input_file="$1"

# Regular expressions to search for
patterns=(
  # API Keys (common prefixes and formats)
  "(API_KEY|api_key|CLIENT_ID|client_id|consumer_key|CONSUMER_KEY)[[:space:]]*=[[:space:]]*['\"]?[a-zA-Z0-9_-]{10,}"
  "(SECRET_KEY|secret_key|CLIENT_SECRET|client_secret|consumer_secret|CONSUMER_SECRET)[[:space:]]*=[[:space:]]*['\"]?[a-zA-Z0-9_-]{20,}"
  "[a-zA-Z0-9]{32}-[-a-zA-Z0-9]{36}" # Example UUID/GUID like keys
  "sk_live_[a-zA-Z0-9_]{20,}"      # Stripe live secret key
  "pk_live_[a-zA-Z0-9_]{20,}"      # Stripe live public key
  "AWS_ACCESS_KEY_ID=[[:alnum:]]+"
  "AWS_SECRET_ACCESS_KEY=[[:alnum:]+/=]+"
  "google_api([[:space:]]*)key[[:space:]]*:[[:space:]]*['\"]?[a-zA-Z0-9_-]+"
  "google_maps_api_key[[:space:]]*=[[:space:]]*['\"]?[a-zA-Z0-9_-]+"
  "reCAPTCHA_site_key[[:space:]]*=[[:space:]]*['\"]?6L[a-zA-Z0-9_-]{37}" # More specific reCAPTCHA

  # Tokens (access tokens, bearer tokens)
  "(access_token|accessToken)[[:space:]]*=[[:space:]]*['\"]?[a-zA-Z0-9_-]{20,}"
  "(auth_token|authToken)[[:space:]]*=[[:space:]]*['\"]?[a-zA-Z0-9_-]{20,}"
  "Authorization:[[:space:]]*Bearer[[:space:]]+[a-zA-Z0-9._-]+"

  # API Endpoints (more specific patterns)
  "https?://[a-zA-Z0-9.-]+\\.[a-z]{2,}(:[0-9]+)?/[a-zA-Z0-9_/.-]+"
  "/[a-zA-Z0-9_/.-]+\\.(json|xml|api)" # Relative API endpoints
)

# Function to download and process a single file
process_file() {
  local file_url="$1"

  # Download the file using curl, with quiet output and fail on error
  curl -sSf "$file_url" -o temp_file.js

  # Check if the download was successful
  if [ $? -ne 0 ]; then
    echo "Failed to download: $file_url"
    return
  fi

  echo "Scanning $file_url"

  found_match=false

  # Loop through each pattern and grep
  for pattern in "${patterns[@]}"; do
    grep -E -n "$pattern" temp_file.js | while IFS=: read -r line_num match; do
      echo "  $file_url:$line_num:$match"
      found_match=true
    done
  done

  # Output "No hit" if no matches found
  if [ ! "$found_match" ]; then
    echo "  No hit"
  fi

  # Remove the temporary file
  rm -f temp_file.js
}

# Main loop: Read each URL from the input file and process it
while IFS= read -r file_url; do
  # Check if the line is not empty and not a comment
  if [[ -n "$file_url" && ! "$file_url" =~ ^# ]]; then
    process_file "$file_url"
  fi
done < "$input_file"

echo "--------------------------------------------------------"
echo "Finished processing files."
