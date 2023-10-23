#!/bin/bash
# https://github.com/bormaxi8080/github-starred-repos-loader.git

#set -e

if [ ${#@} -lt 2 ]; then
    echo "usage: $0 [DESTINATION PATH] [YOUR GITHUB TOKEN]"
    exit 1;
fi

# destination repositories folder
# repository="/Volumes/Transcend/repos"
DESTINATION_PATH=$1
GITHUB_TOKEN=$2

echo "This is script for pull all your GitHub starred repositories to specified folder"
echo "Destination folder: $DESTINATION_PATH"
echo ""

#GITHUB_API_HEADER_ACCEPT="Accept: application/vnd.github.v3+json"
GITHUB_API_HEADER_ACCEPT="Accept: application/vnd.github+json"

GITHUB_API_REST="/user/starred"

# remember current path
CURRENT_PATH="$PWD"

# set repositories counter
COUNTER=0

# shellcheck disable=SC2006
temp=`basename "$0"`
rm -rf "${temp}".tmp

TMPFILE=$(mktemp ./"${temp}".tmp) || exit 1

function rest_call {
    curl -s "$1" -H "${GITHUB_API_HEADER_ACCEPT}" -H "Authorization: token $GITHUB_TOKEN" | \
    grep "clone_url" | \
    sed -e 's/"clone_url": //g; s/,//g; s/"//g; s/ //g' >> "$TMPFILE"
}

echo "Reading data from GitHub..."

# single page result-s (no pagination), have no link: section, the grep result is empty
# curl -s -I "https://api.github.com${GITHUB_API_REST}" \
# -H "${GITHUB_API_HEADER_ACCEPT}" \
# -H "Authorization: token $GITHUB_TOKEN"
last_page=$(curl -s -I "https://api.github.com${GITHUB_API_REST}" -H "${GITHUB_API_HEADER_ACCEPT}" \
-H "Authorization: token $GITHUB_TOKEN" | \
grep '^link:' | \
sed -e 's/^link:.*page=//g' -e 's/>.*$//g')

# does this result use pagination?
if [ -z "$last_page" ]; then
    # no - this result has only one page
    rest_call "https://api.github.com${GITHUB_API_REST}"
else
    # yes - this result is on multiple pages
    for p in $(seq 1 "$last_page"); do
        echo "Page: $p of $last_page"
        rest_call "https://api.github.com${GITHUB_API_REST}?page=$p"
    done
fi

#echo "./${temp}.tmp"
echo ""

while IFS= read -r repo
do
  echo "Cloning $repo"
  echo ""
  # shellcheck disable=SC2164
  cd "$DESTINATION_PATH"
  git clone $repo
  echo ""
  # shellcheck disable=SC2164
  cd "$CURRENT_PATH"
  # shellcheck disable=SC2219
  let "COUNTER+=1"
done < ./"${temp}".tmp

echo "$COUNTER repos cloned"
echo "Done"
