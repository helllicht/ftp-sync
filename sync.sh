#!/bin/bash
# @author: helllicht medien GmbH

for i in "$@"
do
case $i in
    -s=*|--script=*)
    SCRIPT_PATH="${i#*=}"
    shift
    ;;
    -h=*|--host=*)
    HOST="${i#*=}"
    shift
    ;;
    -po=*|--port=*)
    PORT="${i#*=}"
    shift
    ;;
    -u=*|--user=*)
    USER="${i#*=}"
    shift
    ;;
    -p=*|--password=*)
    PASSWORD="${i#*=}"
    shift
    ;;
    -l=*|--local=*)
    UPLOAD="${i#*=}"
    shift
    ;;
    -r=*|--remote=*)
    REMOTE="${i#*=}"
    shift
    ;;
    -S=*|--ssl=*)
    SSL="${i#*=}"
    shift
    ;;
    -P=*|--parallel=*)
    PARALLEL="${i#*=}"
    shift
    ;;
    *)
          # unknown option
    ;;
esac
done

# exit when any command fails
set -e

function fail {
    printf '%s\n' "$1" >&2
    exit "${2-1}"
}

echo "Started sync.sh"

if ! command -v lftp &> /dev/null
then
    # try to install
    echo "lftp not installed, try to install!"
    sudo apt-get install -y lftp

    if ! command -v lftp &> /dev/null
    then
        fail "lftp could not be installed!"
    fi
fi

echo
echo "Installed lftp:"
lftp -v
echo

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Go through the plugin default ignore list and add them to IGNORE
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
IGNORE=''
while read p; do
  # append all entries from .defaultignore
  if [[ ${p:0:1} != "#" ]] ;
  then
    IGNORE="${IGNORE} -X '${p}'"
  fi
done < "${SCRIPT_PATH}/.defaultignore"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Add all empty/0byte files to the .syncignore
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
echo
echo "INFO: lftp has a known issue with 0 byte files (empty files)"
echo "automatically searching for 0 byte files in localDir and add them to .syncignore"
echo

# search for empty/0byte files (ignore the node_modules folder!)
find "$UPLOAD" -type f -empty | sed 's/\.\///g' | grep -v 'node_modules' >> .syncignore

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# If .syncignore exist build the IGNORE and ADD list together
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
if [ -f ".syncignore" ]; then

    # Append to ignore
    while read p; do
      if [ ${#p} -gt 0 ] && [ ${p:0:1} != "#" ] && [ ${p:0:1} != "!" ];
      then
        IGNORE="${IGNORE} -X '${p}'"
      fi
    done < ".syncignore"

    # Append to force add
    while read p; do
      if [ ${#p} -gt 0 ] && [ ${p:0:1} = "!" ] && [ ${p:0:1} != "#" ] ;
      then
        ADD="${ADD} -I '${p:1:999}'"
      fi
    done < ".syncignore"

    echo "ADD: $ADD"
else
    echo "No .syncignore found."
fi

echo "Final ignore list: ${IGNORE}"

# Optional feature for future...
#if test -f "composer.lock"; then
#    # This project contains a composer.lock file
#    echo "This is a php project with composer.lock!"
#    echo "Trying to compare local composer.lock with remote"
#
#    if bash "$SCRIPT_PATH"/composerLockCheck.sh -h="$HOST" -u="$USER" -p="$PASSWORD" -S; then
#        # remote.composer.lock is downloaded
#        echo "Found a composer.lock on remote. Compare with local composer.lock!"
#        # slice the "content-hash" from remote and local to check if they are identically
#        REMOTE_HASH=$(cat remote.composer.lock | grep content-hash | cut -d ':' -f2)
#        LOCAL_HASH=$(cat composer.lock | grep content-hash | cut -d ':' -f2)
#
#        if [ "$REMOTE_HASH" = "$LOCAL_HASH" ]; then
#          echo "composer.lock hashes are same! Automatically add vendor/ (and kirby/) to ignore."
#          IGNORE="${IGNORE} -X 'vendor/'"
#          IGNORE="${IGNORE} -X 'kirby/'"
#        fi
#    else
#        # no remote.composer.lock
#        echo "No composer.lock could be found on remote host. Will upload vendor/ (and kirby/)."
#    fi
#fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Echo optional options that where set / other information
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

FORCE_SSL=""
if [ "$SSL" = "true" ]; then
  echo "ssl-force enabled!"
  FORCE_SSL="set ftp:ssl-force true;"
else
  echo "ssl-force disabled!"
  FORCE_SSL="set ftp:ssl-force false;"
fi

SPECIFIC_PORT=""
if [ "$PORT" != "" ]; then
  echo "specific port was given. Add -p $PORT"
  SPECIFIC_PORT="-p $PORT"
fi

echo "Parallel is set to: $PARALLEL"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Start the "real" upload process
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
echo
echo " --- Start sync process ---"
echo

# lftp manual: http://lftp.yar.ru/lftp-man.html
# if we got ssl issues probably set 'set ssl:verify-certificate no'

# INFO for debug,
# debug   <- output everything
# debug 3 <- output just errors

lftp "$SPECIFIC_PORT" -u "$USER","$PASSWORD" "$HOST" <<EOF
set sftp:auto-confirm yes;
set ssl:verify-certificate no;
set net:timeout 15;
set net:reconnect-interval-base 5;
set net:max-retries 2;
$FORCE_SSL
mirror --reverse --parallel=$PARALLEL --verbose --only-newer $UPLOAD $REMOTE $IGNORE;
exit
EOF

echo
echo " --- Finished sync process ---"
echo

exit 0
