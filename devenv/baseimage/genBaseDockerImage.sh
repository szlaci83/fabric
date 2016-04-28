#!/bin/bash

RELEASE=0.0.10
MACHINE=`uname -m`
NAME=openblockchain/$MACHINE/baseimage:$RELEASE
BASEOS=ubuntu:trusty
if [ x$MACHINE = xs390x ]
then
    BASEOS=s390x/ubuntu
elif [ x$MACHINE = xppc64 ]
then
    echo "TODO: Add PPC support"
    exit
fi


cat > Dockerfile <<HEREDOC

FROM $BASEOS
RUN mkdir /tmp/setup
COPY scripts /tmp/setup
WORKDIR /tmp/setup
RUN common/init.sh && docker/init.sh && common/setup.sh
HEREDOC

docker build -t $NAME .

echo done
