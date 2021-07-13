#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER1_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt
export PEER2_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer2.org1.example.com/tls/ca.crt

export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER1_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt
export PEER2_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer2.org2.example.com/tls/ca.crt

#export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
#export PEER1_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls/ca.crt

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
  export CORE_PEER_LOCALMSPID="OrdererMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp
}

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  #echo "Using organization ${USING_ORG}"

  # modified at 2020.9.8, due to unstable result of hostname -I
  HOST_STR=$(hostname -I)
  # HOST_1="172.30.0.204"
  # HOST_2="172.30.0.59"
  # HOST_3="172.30.0.178"
  # HOST_4="172.30.0.80"
  # HOST_5="172.30.0.186"
  # HOST_6="172.30.0.74"

  HOST_1=$HOST1_PVT_IP
  HOST_2=$HOST2_PVT_IP
  HOST_3=$HOST3_PVT_IP
  HOST_4=$HOST4_PVT_IP
  HOST_5=$HOST5_PVT_IP
  HOST_6=$HOST6_PVT_IP

if [[ "$HOST_STR" == *${HOST_1}* ]]; then
	PEER_NAME="peer0.org1.example.com"
	HOST_IP=$HOST_1
elif [[ "$HOST_STR" == *${HOST_2}* ]]; then
	PEER_NAME="peer1.org1.example.com"
	HOST_IP=$HOST_2
elif [[ "$HOST_STR" == *${HOST_3}* ]]; then
	PEER_NAME="peer2.org1.example.com"
	HOST_IP=$HOST_3
elif [[ "$HOST_STR" == *${HOST_4}* ]]; then
	PEER_NAME="peer0.org2.example.com"
	HOST_IP=$HOST_4
elif [[ "$HOST_STR" == *${HOST_5}* ]]; then
	PEER_NAME="peer1.org2.example.com"
	HOST_IP=$HOST_5
elif [[ "$HOST_STR" == *${HOST_6}* ]]; then
	PEER_NAME="peer2.org2.example.com"
	HOST_IP=$HOST_6
else
	PPER_NAME="unknown host, IP not recognizaed: $HOST_STR"
fi

echo "Host in execution with network.sh: $PEER_NAME---$HOST_IP"

  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp

    if [ "$HOST_IP" == ${HOST_1} ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
      export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
    elif [ "$HOST_IP" == ${HOST_2} ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_ORG1_CA
      export CORE_PEER_ADDRESS=peer1.org1.example.com:7051
    elif [ "$HOST_IP" == ${HOST_3} ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER2_ORG1_CA
      export CORE_PEER_ADDRESS=peer2.org1.example.com:7051
    else
      export CORE_PEER_ADDRESS=localhost:7051
    fi

  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    #export CORE_PEER_ADDRESS=localhost:7051
    if [ "$HOST_IP" == ${HOST_4} ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
      export CORE_PEER_ADDRESS=peer0.org2.example.com:7051
    elif [ "$HOST_IP" == ${HOST_5} ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_ORG2_CA
      export CORE_PEER_ADDRESS=peer1.org2.example.com:7051
    elif [ "$HOST_IP" == ${HOST_6} ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_ORG2_CA
      export CORE_PEER_ADDRESS=peer2.org2.example.com:7051
    else
      export CORE_PEER_ADDRESS=localhost:7051
    fi
  #elif [ $USING_ORG -eq 3 ]; then
  #  export CORE_PEER_LOCALMSPID="Org3MSP"
  #  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
  #  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    # when add org3 with multiple peers, should change CORE_PEER_TLS_ROOTCERT_FILE and CORE_PEER_ADDRESS
  #  export CORE_PEER_ADDRESS=localhost:7051
    # change localhost into your own ip
  else
    echo "================== ERROR !!! ORG Unknown =================="
  fi

  echo "----------------------end of setGlobal(): using CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS"

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}


# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode operation

parsePeerConnectionParameters() {

  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## Set peer adresses
    PEERS="$PEERS $PEER"
    echo "--------------in parsePeerConnectionParams: Using Org${USING_ORG}, PEERS=$PEERS"
    # modified at 2020.8.23
    # this func is called by ChaincodeInvokeInit() and commitChaincodeDefinition() in deployCC_step2.sh
    # to replace the "localhost:7051" setting in setGlobals

    #########################################################
    # May cause problem by using CORE_PEER_ADDRESS directly here
    #########################################################
    if [ $PEER == "peer0.org1" ]; then
      #export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
      PEER_ADDRESS=peer0.org1.example.com:7051

    elif [ $PEER == "peer0.org2" ]; then
      #export CORE_PEER_ADDRESS=peer0.org2.example.com:7051
      PEER_ADDRESS=peer0.org2.example.com:7051
    else
      echo "unknown org for CORE_PEER_ADDRESS assignment"
    fi

    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $PEER_ADDRESS"
    ## Set path to TLS certificate
    TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER0_ORG$1_CA")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    # shift by one to get to the next organization
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"

  echo "End of parsePeerConnectionParams: PEER_CONN_PARMS=$PEER_CONN_PARMS $TLSINFO"
  echo
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo $'\e[1;31m'!!!!!!!!!!!!!!! $2 !!!!!!!!!!!!!!!!$'\e[0m'
    echo
    exit 1
  fi
}

# to run command in terminal, set following env values:
#export PATH=${PWD}/../bin:$PATH
#export FABRIC_CFG_PATH=$PWD/../config/
#export CORE_PEER_TLS_ENABLED=true
#export CORE_PEER_LOCALMSPID="Org1MSP"
#export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
#export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
#export CORE_PEER_ADDRESS=localhost:7051
