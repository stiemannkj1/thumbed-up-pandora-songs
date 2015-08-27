#!/bin/bash

###############################################################################
#
# The MIT License (MIT)
# 
# Copyright (c) 2015 Kyle J. Stiemann
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
###############################################################################

if hash curl 2>/dev/null; then
	GET_URL_COMMAND="curl --silent"
elif hash wget 2>/dev/null; then
	GET_URL_COMMAND="wget --quiet --output-document -"
else
	printf 'This program requires wget or curl. Please install wget or curl and run this program again.\n'
	exit 1
fi

if ! hash sed 2>/dev/null; then
	printf 'This program requires sed. Please install sed and run this program again.\n'
	exit 1
fi

STATION_URL="$1"

if [ -z "$STATION_URL" ]; then
	printf 'Enter your pandora.com station URL:\n'
	read STATION_URL
fi

STATION_ID="$STATION_URL"
STATION_ID="${STATION_ID#http://www.pandora.com/station/play/}"
STATION_ID="${STATION_ID#http://www.pandora.com/station/}"
STATION_ID="${STATION_ID%[?]*}"

if [[ "$STATION_ID" =~ [^0-9] ]]; then
	printf 'Please enter a valid pandora.com station URL of the form:\n'
	printf 'http://www.pandora.com/station/play/0000000000000000000\n'
	exit 1
fi

THUMBS_BASE_URL="http://www.pandora.com/content/station_track_thumbs"
DELIMITER=";"

get_thumbed_up_songs() {
	INDEX=$1
	$GET_URL_COMMAND "$THUMBS_BASE_URL?stationId=$STATION_ID&posFeedbackStartIndex=$INDEX&posSortBy=artist" | \
	sed \
	-e "s/a> by <a/a>$DELIMITER<a/g" \
	-e 's/<[^>]*>//g' \
	-e 's/[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]//' \
	-e '/^[[:space:]]*$/d' \
	-e 's/^[[:space:]]*//g' \
	-e 's/[[:space:]]*$//g' \
	-e '/Show more/d' \
	-e 's/\&amp;/\&/g'
}

INDEX=0

ALL_THUMBED_UP_SONGS="$(get_thumbed_up_songs 0)"

if [ -z "$ALL_THUMBED_UP_SONGS" ]; then
	printf "$STATION_URL does not exist\n"
	exit 1
fi

# Getting artists with index=0 and index=5 only yields 5 artists, so getting the first 10 artists must be done
# outside of the loop.
INDEX=5

THUMBED_UP_SONGS="$(get_thumbed_up_songs 5)"

INDEX=10

while [[ $ALL_THUMBED_UP_SONGS != *$THUMBED_UP_SONGS* ]]; do
	ALL_THUMBED_UP_SONGS="$ALL_THUMBED_UP_SONGS\n$THUMBED_UP_SONGS"
	THUMBED_UP_SONGS="$(get_thumbed_up_songs "$INDEX")"
	INDEX=$((INDEX+10))
done

printf "Song Title${DELIMITER}Artist\n$ALL_THUMBED_UP_SONGS\n"

# If the output is not being piped, then...
if [ -t 1 ]; then
	# ... the user may be running the script via the *Open With* > *Terminal* method, so ensure that the terminal
	# remains open so that they can copy their results.
	printf '\nPress Enter to exit the program.\n'
	read
fi
