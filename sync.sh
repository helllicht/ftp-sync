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

echo "starting sync.sh script"

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

IGNORE=''
while read p; do
  # append all entries from .defaultignore
  if [[ ${p:0:1} != "#" ]] ;
  then
    IGNORE="${IGNORE} -X '${p}'"
  fi
done < "${SCRIPT_PATH}/.defaultignore"

if [ -f ".syncignore" ]; then
    # if exists, append all entries from .syncignore
    echo ".syncignore exists."

    while read p; do
      if [ ${#p} -gt 0 ] && [ ${p:0:1} != "#" ] ;
      then
        IGNORE="${IGNORE} -X '${p}'"
      fi
    done < ".syncignore"

    echo "Added additional ignores from .syncignore!"
else
    echo "No .syncignore found."
fi

if test -f "composer.lock"; then
    # This project contains a composer.lock file
    echo "This is a php project with composer.lock!"
    echo "Trying to compare local composer.lock with remote"

    if bash "$SCRIPT_PATH"/composerLockCheck.sh -h="$HOST" -u="$USER" -p="$PASSWORD" -S; then
        # remote.composer.lock is downloaded
        echo "Found a composer.lock on remote. Compare with local composer.lock!"
        # slice the "content-hash" from remote and local to check if they are identically
        REMOTE_HASH=$(cat remote.composer.lock | grep content-hash | cut -d ':' -f2)
        LOCAL_HASH=$(cat composer.lock | grep content-hash | cut -d ':' -f2)

        if [ "$REMOTE_HASH" = "$LOCAL_HASH" ]; then
          echo "composer.lock hashes are same! Automatically add vendor/ (and kirby/) to ignore."
          IGNORE="${IGNORE} -X 'vendor/'"
          IGNORE="${IGNORE} -X 'kirby/'"
        fi
    else
        # no remote.composer.lock
        echo "No composer.lock could be found on remote host. Will upload vendor/ (and kirby/)."
    fi
fi

echo "Final ignore list: ${IGNORE}"

# additional settings
FORCE_SSL=""
if [ "$SSL" = "true" ]; then
  echo "ssl-force enabled!"
  FORCE_SSL="set ftp:ssl-force true"
else
  echo "ssl-force disabled!"
  FORCE_SSL="set ftp:ssl-force false"
fi

echo
echo " --- Start sync process ---"

# lftp manual: http://lftp.yar.ru/lftp-man.html
# if we got ssl issues probably set 'set ssl:verify-certificate no'

lftp -u "$USER","$PASSWORD" $HOST <<EOF
debug
set ssl:check-hostname no
set sftp:auto-confirm yes
$FORCE_SSL
mirror --verbose --reverse --only-newer --delete $UPLOAD $REMOTE $IGNORE;
exit
EOF

echo " --- Finished sync process ---"
echo

exit 0
