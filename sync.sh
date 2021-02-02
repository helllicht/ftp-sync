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
  # optional escaping (not needed?)
  # IGNORE="${IGNORE} -x '${p//./\\.}'"

  # use of -X not -x see https://github.com/lavv17/lftp/issues/604#issuecomment-701397054
  if [[ ${p:0:1} != "#" ]] ;
  then
    IGNORE="${IGNORE} -X '${p}'"
  fi
done < "${SCRIPT_PATH}/.defaultignore"

if [ -f ".syncignore" ]; then
    echo ".syncignore exists."

    while read p; do
      if [[ ${p:0:1} != "#" ]] ;
      then
        IGNORE="${IGNORE} -X '${p}'"
      fi
    done < ".syncignore"

    echo "Added additional ignores from .syncignore!"
else
    echo "No .syncignore found."
fi

echo "Compare composer.lock with remote"
if bash "$SCRIPT_PATH"/cLockCheck.sh -h="$HOST" -u="$USER" -p="$PASSWORD"; then
    # remote.composer.lock is downloaded
    echo "Found a composer.lock on remote. Compare with current composer.lock!"
    REMOTE_HASH=$(cat remote.composer.lock | grep content-hash | cut -d ':' -f2)
    LOCAL_HASH=$(cat composer.lock | grep content-hash | cut -d ':' -f2)

    if [ "$REMOTE_HASH" = "$LOCAL_HASH" ]; then
      echo "composer.lock hashes are same on local and remote! Automatically add vendor/ (and kirby/) to ignore."
      IGNORE="${IGNORE} -X 'vendor/'"
      IGNORE="${IGNORE} -X 'kirby/'"
    fi
else
    # no remote.composer.lock
    echo "No composer.lock could be found on remote host. Will upload vendor/ (and kirby/)."
fi

echo "Final ignore list: ${IGNORE}"

echo
echo " --- Start sync process ---"

lftp -u "$USER","$PASSWORD" $HOST <<EOF
# the next 3 lines put you in ftp mode. Uncomment if you are having trouble connecting.
# set ftp:ssl-force true
# set ftp:ssl-protect-data true
# set ssl:verify-certificate no
# transfer starts now...
set sftp:auto-confirm yes
mirror -R $UPLOAD $REMOTE --delete $IGNORE;
exit
EOF
echo
echo " --- Finished sync process ---"

exit 0
