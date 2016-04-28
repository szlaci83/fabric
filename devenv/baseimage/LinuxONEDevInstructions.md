Adapted from https://github.com/linux-on-ibm-z/docs/wiki/Building-Open-Ledger

Start docker daemon: (download from https://www.ibm.com/developerworks/linux/linux390/docker.html)
      sudo su
      wget ftp://ftp.unicamp.br/pub/linuxpatch/s390x/redhat/rhel7.2/docker-1.10.1-rhel7.2-20160408.tar.gz 
      tar -xvzf docker-1.10.1-rhel7.2-20160408.tar.gz
      cp docker-1.10.1-rhel7.2-20160408/docker /bin
      docker daemon -D -g /data/docker -r=true --api-enable-cors=true -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock

#GOLANG BUILD: (from https://github.com/linux-on-ibm-z/docs/wiki/Building-Go)

      mkdir -p /home/linux1/git/src/github.com/linux-on-ibm-z
      cd /home/linux1/git/src/github.com/linux-on-ibm-z
      git clone http://github.com/linux-on-ibm-z/go.git
      git checkout release-branch.go1.6
      docker run --privileged --rm -ti -v /home/linux1/git/src/github.com:/home/linux1/git/src/github.com brunswickheads/openchain-peer /bin/bash

      <inside docker>
      cd /home/linux1/git/src/github.com/linux-on-ibm-z/go/src/
      yum install -y git wget tar gcc bzip2
      export GOROOT_BOOTSTRAP=/usr/local/go
      GOOS=linux GOARCH=s390x ./bootstrap.bash
      <exit docker>

      export GOROOT_BOOTSTRAP=/home/linux1/git/src/github.com/linux-on-ibm-z/go-linux-s390x-bootstrap
      cd /home/linux1/git/src/github.com/linux-on-ibm-z/go/src
      ./all.bash
      export PATH=/home/linux1/git/src/github.com/linux-on-ibm-z/go/bin:$PATH


#ROCKSDB BUILD

      cd /home/linux1/git/src/github.com
      yum install gcc-c++ snappy snappy-devel zlib zlib-devel bzip2 bzip2-devel
      mkdir facebook
      cd facebook
      git clone https://github.com/facebook/rocksdb.git
      cd  rocksdb
      make shared_lib && INSTALL_PATH=/usr make install-shared && ldconfig


#HYPERLEDGER! (from https://github.com/hyperledger/fabric/blob/master/README.md)

      <env> (suggest add to .bashrc)
      export PATH=/home/linux1/git/src/github.com/linux-on-ibm-z/go/bin:$PATH
      export GOROOT=/home/linux1/git/src/github.com/linux-on-ibm-z/go
      export GOPATH=/home/linux1/git
      <env>

      mkdir /home/linux1/git/src/github.com/hyperledger
      cd /home/linux1/git/src/github.com/hyperledger
      git clone https://github.com/vpaprots/fabric.git
      cd fabric
      go build -o peer
      ./peer
      tar -cvzf devenv/baseimage/s390x/go-linux-s390x.tar.gz -C ../../linux-on-ibm-z go
      docker build -t openblockchain/s390x/baseimage devenv/baseimage/s390x
      rm devenv/baseimage/s390x/go-linux-s390x.tar.gz
      go test github.com/hyperledger/fabric/core/container -run=BuildImage_Peer
      go test github.com/hyperledger/fabric/core/container -run=BuildImage_Obcca

#TESTING (from https://github.com/hyperledger/fabric/blob/master/README.md)

      ./peer peer
 
      # New Term
      cd $GOPATH/src/github.com/hyperledger/fabric
      go test -timeout=20m $(go list github.com/hyperledger/fabric/... | grep -v /vendor/ | grep -v /examples/)
    
      #FIXME behave not found: install dependencies from devenv/setup.sh
      cd $GOPATH/src/github.com/hyperledger/fabric/bddtests
      behave

#PEER NETWORK (from https://github.com/hyperledger/fabric/blob/master/docs/dev-setup/devnet-setup.md)

      docker run --rm -it -e CORE_VM_ENDPOINT=http://172.17.0.1:4243 -e CORE_PEER_ID=vp1 -e CORE_PEER_ADDRESSAUTODETECT=true hyperledger-peer ./peer peer
      docker run --rm -it -e CORE_VM_ENDPOINT=http://172.17.0.1:4243 -e CORE_PEER_ID=vp1 -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_PEER_DISCOVERY_ROOTNODE=172.17.0.2:30303 hyperledger-peer ./peer peer
      <repeat line above for more peers>


      export NAME=`CORE_PEER_ADDRESS=172.17.0.2:30303 ./peer chaincode deploy -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -c '{"Function":"init", "Args": ["a","100", "b", "200"]}'`
      CORE_PEER_ADDRESS=172.17.0.2:30303 ./peer chaincode invoke -n $NAME -c '{"Function": "invoke", "Args": ["a", "b", "10"]}'


#References and Notes
Firewall disable: iptables -I INPUT 1 -j ACCEPT
Memory overcomit: sysctl vm.overcommit_memory=1
Protocol SPEC: https://github.com/openblockchain/obc-docs/blob/master/protocol-spec.md
Sinenomine ClefOS docker image: https://hub.docker.com/r/brunswickheads/openchain-peer

