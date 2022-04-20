#!/usr/bin/env bash

set -e

DEBFILE=$1
RELTYPE=$2

if [ "$DEBFILE" == "" ]; then
  echo "Usage: aptly.sh <deb file> <release type>"
  echo "   release type = $RELTYPE or stable (default: $RELTYPE)"
  exit 1
fi

if [ "$RELTYPE" == "" ]; then
  RELTYPE="nightly"
fi

# Look to see if we need to install aptly
if ! dpkg-query -W | grep -q aptly ; then
 wget -qO - https://www.aptly.info/pubkey.txt | gpg --dearmor  > aptly.gpg
 sudo install -o root -g root -m 644 aptly.gpg /etc/apt/trusted.gpg.d/
 echo "deb http://repo.aptly.info/ squeeze main" | sudo tee -a /etc/apt/sources.list
 sudo sort -u /etc/apt/sources.list -o /etc/apt/sources.list
 sudo apt-get -qq update
 sudo apt-get -qq install -y aptly
fi

# ensure .gnupg has been initialized
mkdir -p ~/.gnupg/private-keys-v1.d
touch ~/.gnupg/trustedkeys.gpg
chmod 600 ~/.gnupg/*
chmod 700 ~/.gnupg
chmod 700 ~/.gnupg/private-keys-v1.d

# import the private key
echo $GPG_KEY | base64 -d | gpg -q --import

# export and import the public key so aptly can access it
gpg --export -a | gpg -q --batch --no-default-keyring --keyring trustedkeys.gpg --import

# cleanup old runs
rm -rf /tmp/aptly || test true

# create the aptly config file
cat > /tmp/aptly.conf << EOL
{
  "rootDir": "/tmp/aptly",
  "downloadConcurrency": 4,
  "downloadSpeedLimit": 0,
  "architectures": [],
  "dependencyFollowSuggests": false,
  "dependencyFollowRecommends": false,
  "dependencyFollowAllVariants": false,
  "dependencyFollowSource": false,
  "dependencyVerboseResolve": false,
  "gpgDisableSign": false,
  "gpgDisableVerify": false,
  "gpgProvider": "gpg",
  "downloadSourcePackages": false,
  "skipLegacyPool": true,
  "ppaDistributorID": "ubuntu",
  "ppaCodename": ""
}
EOL

# create a mirror from public site
aptly mirror create -config=/tmp/aptly.conf $RELTYPE http://35.211.228.244/repos/$RELTYPE focal
aptly mirror update -config=/tmp/aptly.conf $RELTYPE
aptly snapshot create -config=/tmp/aptly.conf public-snap from mirror $RELTYPE

# create a local repo, add deb and snapshot
aptly repo create -config=/tmp/aptly.conf $RELTYPE
aptly repo add -config=/tmp/aptly.conf $RELTYPE $DEBFILE
aptly snapshot -config=/tmp/aptly.conf create $RELTYPE-snap from repo $RELTYPE

# merge the public snap and local
aptly snapshot merge -config=/tmp/aptly.conf -no-remove $RELTYPE $RELTYPE-snap public-snap

# publish the merged snapshot
aptly publish snapshot -batch -passphrase="" -config=/tmp/aptly.conf $RELTYPE $RELTYPE

# copy new public repo to GCS
gsutil -m rsync -r /tmp/aptly/public/$RELTYPE gs://debrepo/repos/$RELTYPE
