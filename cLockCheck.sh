#!/bin/bash
# @author: helllicht medien GmbH

# This script returns 0 (success) if it could download the composer.lock else 1 (fail)

echo "start cLockCheck"

lftp -u "$USER","$PASSWORD" $HOST <<EOF
set sftp:auto-confirm yes
get -c composer.lock -o remote.composer.lock
exit
EOF

if test -f "remote.composer.lock"; then
    exit 0
else
    exit 1
fi
