#!/bin/bash
# @author: helllicht medien GmbH

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

HOST="${inputs.host}"
USER="${inputs.username}"
PASSWORD="${inputs.password}"
UPLOAD="${inputs.localDir}"
REMOTE="${inputs.uploadPath}"

IGNORE=''
while read p; do
  # optional escaping (not needed?)
  # IGNORE="${IGNORE} -x '${p//./\\.}'"

  # use of -X not -x see https://github.com/lavv17/lftp/issues/604#issuecomment-701397054
  IGNORE="${IGNORE} -X '${p}'"
done < "${{ github.action_path }}/.defaultignore"

echo "Ignore: ${IGNORE}"

lftp -u "$USER","$PASSWORD" $HOST <<EOF
# the next 3 lines put you in ftp mode. Uncomment if you are having trouble connecting.
# set ftp:ssl-force true
# set ftp:ssl-protect-data true
# set ssl:verify-certificate no
# transfer starts now...
set sftp:auto-confirm yes
mirror -R $(pwd)$UPLOAD $REMOTE --delete $IGNORE;
exit
EOF
echo
echo "done"

exit 0
