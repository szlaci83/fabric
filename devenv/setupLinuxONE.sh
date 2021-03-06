#!/bin/bash

# To get started:
#       sudo su
#       yum install git
#       mkdir -p $HOME/git/src/github.com/hyperledger
#       cd $HOME/git/src/github.com/hyperledger
#       git clone https://github.com/vpaprots/fabric.git
#       source fabric/devenv/setupLinuxONE.sh
#       ~/build.sh

if [ xroot != x$(whoami) ]
then
   echo "You must run as root (Hint: sudo su)"
   exit
fi

if [ -n -d $HOME/git/src/github.com/hyperledger/fabric ]
then
    echo "Script fabric code is under $HOME/git/src/github.com/hyperledger/fabric "
    exit
fi

set -x

#TODO: should really just open a few ports..
iptables -I INPUT 1 -j ACCEPT
sysctl vm.overcommit_memory=1

##################
# Install Docker
cd /tmp
wget ftp://ftp.unicamp.br/pub/linuxpatch/s390x/redhat/rhel7.2/docker-1.10.1-rhel7.2-20160408.tar.gz
tar -xvzf docker-1.10.1-rhel7.2-20160408.tar.gz
cp docker-1.10.1-rhel7.2-20160408/docker /bin
rm -rf docker docker-1.10.1-rhel7.2-20160408.tar.gz

#TODO: Install on boot
nohup docker daemon -g /data/docker -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock&

###################################
# Crosscompile and install GOLANG
cd $HOME
git clone http://github.com/linux-on-ibm-z/go.git
cd go
git checkout release-branch.go1.6

cat > crosscompile.sh <<HEREDOC
cd /tmp/home/go/src	
yum install -y git wget tar gcc bzip2
export GOROOT_BOOTSTRAP=/usr/local/go
GOOS=linux GOARCH=s390x ./bootstrap.bash
HEREDOC

docker run --privileged --rm -ti -v $HOME:/tmp/home brunswickheads/openchain-peer /bin/bash /tmp/home/go/crosscompile.sh

export GOROOT_BOOTSTRAP=$HOME/go-linux-s390x-bootstrap
cd $HOME/go/src
./all.bash
export PATH=$HOME/go/bin:$PATH

rm -rf $HOME/go-linux-s390x-bootstrap 

################
#ROCKSDB BUILD

cd /tmp
yum install -y gcc-c++ snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel
git clone https://github.com/facebook/rocksdb.git
cd  rocksdb
git checkout tags/v4.1
echo There were some bugs in 4.1 for x/p, dev stream has the fix, living dangereously, fixing in place
sed -i -e "s/-march=native/-march=zEC12/" build_tools/build_detect_platform
sed -i -e "s/-momit-leaf-frame-pointer/-DDUMBDUMMY/" Makefile
make shared_lib && INSTALL_PATH=/usr make install-shared && ldconfig
cd /tmp
rm -rf /tmp/rocksdb

################
# PIP
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python-pip-7.1.0-1.el7.noarch.rpm
rpm -ivh python-pip-7.1.0-1.el7.noarch.rpm
pip install behave nose docker-compose

# updater-server, update-engine, and update-service-common dependencies (for running locally)
pip install -I flask==0.10.1 python-dateutil==2.2 pytz==2014.3 pyyaml==3.10 couchdb==1.0 flask-cors==2.0.1 requests==2.4.3
cat >> ~/.bashrc <<HEREDOC
      export PATH=$HOME/go/bin:$PATH
      export GOROOT=$HOME/go
      export GOPATH=$HOME/git
HEREDOC

source ~/.bashrc

cat > ~/build.sh <<HEREDOC
      set -x 
      
      cd $HOME/git/src/github.com/hyperledger/fabric/peer
      go build
      ./peer
      
      cd $HOME/git/src/github.com/hyperledger/fabric/devenv/baseimage
      make docker
      
      cd $HOME/git/src/github.com/hyperledger/fabric/scripts/provision/
      ./docker.sh 0.0.10
      
      go test github.com/hyperledger/fabric/core/container -run=BuildImage_Peer
      go test github.com/hyperledger/fabric/core/container -run=BuildImage_Obcca

      cd $HOME/git/src/github.com/hyperledger/fabric
      ./peer peer&
      pid=$!
      go test -timeout=20m \$(go list github.com/hyperledger/fabric/... | grep -v /vendor/ | grep -v /examples/)
      kill $pid
      
      cd $HOME/git/src/github.com/hyperledger/fabric/bddtests
      behave

HEREDOC
chmod +x ~/build.sh
