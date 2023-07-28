#!/bin/bash
set -uex

# Note this script assumes you have set up the env vars something like below
# according to https://wiki.canonical.com/engineering/OpenStack/OSCI/OSCIFYYourBastion
#export TEST_CIDR_END=172.20.0.254
#export TEST_CIDR_EXT=172.20.0.0/24
#export TEST_FIP_RANGE=172.20.0.150:172.20.0.230
#export TEST_GATEWAY=172.20.0.1
#export TEST_NAME_SERVER=172.20.0.2

# We need exactly two params, the test bundle e.g. jammy-zed and the source (e.g. proposed or cloud:focal-xena/proposed)
bundle="${1:?missing}"
source="${2:?missing}"


export OS_TEST_HTTP_PROXY=http://squid.internal:3128/
export TEST_HTTP_PROXY=http://squid.internal:3128/
export TEST_SWIFT_IP=10.245.161.162
export TEST_CEPH_SOURCE="${source}"


tox -e func-target -- "${bundle}"

models="$( juju models | awk '/zaza-/{ print $1 }' | tr -d '*' )"
let i="$( echo $models |wc -l )"
if (( i != 1 )) ; then
    echo "Looking for exactly 1 zaza model but found $i, bailing"
    echo "Please choose model and check package version numbers"
    exit
fi

juju run -m $models -a ceph-mon,ceph-osd,ceph-fs 'apt-cache policy ceph-common'

juju run -m $models -a ceph-mon,ceph-osd,ceph-fs 'apt-cache policy ceph-common' | fgrep Installed:

