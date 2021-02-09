#!/bin/bash
# @author: helllicht medien GmbH

# This script returns 0 (success) if it could download the composer.lock else 1 (fail)

for i in "$@"
do
case $i in
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
    -S=*|--ssl=*)
    SSL="${i#*=}"
    shift
    ;;
    *)
          # unknown option
    ;;
esac
done

# additional settings
FORCE_SSL=""
if [ "$SSL" = "true" ]; then
  FORCE_SSL="set ftp:ssl-force true"
else
  FORCE_SSL="set ftp:ssl-force false"
fi

echo
echo "try to download composer.lock on remote"

lftp -u "$USER","$PASSWORD" $HOST <<EOF
set ssl:check-hostname no
set sftp:auto-confirm yes
$FORCE_SSL
get -c composer.lock -o remote.composer.lock
exit
EOF

if test -f "remote.composer.lock"; then
    exit 0
else
    exit 1
fi
