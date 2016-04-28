#!/bin/bash

RELEASE=0.0.10
GOARCH=`go env GOARCH`
NAME=openblockchain/$GOARCH/baseimage:$RELEASE
BASEOS=ubuntu:trusty
if [ x$GOARCH = xs390x ]
then
    BASEOS=s390x/ubuntu
elif [ x$GOARCH = xppc64 ]
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

rm Dockerfile

echo done
