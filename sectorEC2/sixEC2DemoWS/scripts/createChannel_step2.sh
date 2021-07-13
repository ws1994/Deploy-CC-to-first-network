#!/bin/bash


CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

# import utils
. scripts/envVar.sh

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelTx() {

	set -x
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate channel configuration transaction..."
		exit 1
	fi
	echo

}

createAncorPeerTx() {
	# remove Org2MSP from list
	for orgmsp in Org1MSP Org2MSP; do

	echo "#######    Generating anchor peer update for ${orgmsp}  ##########"
	set -x
	configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate anchor peer update for ${orgmsp}..."
		exit 1
	fi
	echo
	done
}

createChannel() {
	setGlobals 1

	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        set -x
				# use public ip of orderer here
				peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block >&log.txt
				res=$?
        set +x
		else
				set -x
				# use public ip of orderer here
				peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.example.com -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
				res=$?
				set +x
		fi
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Verify: Channel creation failed."
	echo
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

# queryCommitted ORG
joinChannel() {
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	echo
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

updateAnchorPeers() {
  ORG=$1
  setGlobals $ORG

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer channel update -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
    res=$?
    set +x
  else
    set -x
    peer channel update -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "
  sleep $DELAY
  echo
}

updateAnchorPeers_localOrder() {
  ORG=$1
  setGlobals $ORG

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
    res=$?
    set +x
  else
    set -x
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "
  sleep $DELAY
  echo
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
    echo
    exit 1
  fi
}


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

export GODEBUG=netdns=go
# this is to use core.yaml in dir:/fabric-samples/config
FABRIC_CFG_PATH=$PWD/../config/

if [ "$HOST_IP" == "$HOST_1" ]; then
	echo "Updating anchor peers for org1..."
	updateAnchorPeers_localOrder 1
	echo "================== ${PEER_NAME} update anchor peers successfully! ================== "
elif [ "$HOST_IP" == "$HOST_4" ]; then
	echo "Updating anchor peers for org1..."
	updateAnchorPeers 2
	echo "========= ${PEER_NAME} update anchor peers successfully! =========== "
else
	echo "Non-anchor peer does not need to update"
fi

exit 0
