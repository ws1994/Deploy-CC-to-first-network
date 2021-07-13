
CHANNEL_NAME=${1:-"mychannel"}
CC_NAME=${2:-"basic"}
#CC_NAME=${2:-"ledger"}
CC_SRC_PATH=${3:-"NA"}
CC_SRC_LANGUAGE=${4:-"go"}
CC_VERSION=${5:-"1.0"}
CC_SEQUENCE=${6:-"1"}
#CC_INIT_FCN=${7:-"NA"}
# basic chaincode has func 'initLedger'
CC_INIT_FCN=${7:-"YES"}
CC_END_POLICY=${8:-"NA"}
CC_COLL_CONFIG=${9:-"NA"}
DELAY=${10:-"3"}
MAX_RETRY=${11:-"5"}
VERBOSE=${12:-"false"}

echo --- executing with the following
echo   - CHANNEL_NAME:$'\e[0;32m'$CHANNEL_NAME$'\e[0m'
echo   - CC_NAME:$'\e[0;32m'$CC_NAME$'\e[0m'
echo   - CC_SRC_PATH:$'\e[0;32m'$CC_SRC_PATH$'\e[0m'
echo   - CC_SRC_LANGUAGE:$'\e[0;32m'$CC_SRC_LANGUAGE$'\e[0m'
echo   - CC_VERSION:$'\e[0;32m'$CC_VERSION$'\e[0m'
echo   - CC_SEQUENCE:$'\e[0;32m'$CC_SEQUENCE$'\e[0m'
echo   - CC_END_POLICY:$'\e[0;32m'$CC_END_POLICY$'\e[0m'
echo   - CC_COLL_CONFIG:$'\e[0;32m'$CC_COLL_CONFIG$'\e[0m'
echo   - CC_INIT_FCN:$'\e[0;32m'$CC_INIT_FCN$'\e[0m'
echo   - DELAY:$'\e[0;32m'$DELAY$'\e[0m'
echo   - MAX_RETRY:$'\e[0;32m'$MAX_RETRY$'\e[0m'
echo   - VERBOSE:$'\e[0;32m'$VERBOSE$'\e[0m'

CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`

FABRIC_CFG_PATH=$PWD/../config/


# User has not provided a path, therefore the CC_NAME must
# be the short name of a known chaincode sample
echo "CC_SRC_PATH=$CC_SRC_PATH"

if [ "$CC_SRC_PATH" = "NA" ]; then
	echo Determining the path to the chaincode
	# first see which chaincode we have. This will be based on the
	# short name of the known chaincode sample
	if [ "$CC_NAME" = "basic" ]; then
		echo $'\e[0;32m'asset-transfer-basic$'\e[0m' chaincode
		CC_SRC_PATH="../asset-transfer-basic"
	elif [ "$CC_NAME" = "secured" ]; then
		echo $'\e[0;32m'asset-transfer-secured-agreeement$'\e[0m' chaincode
		CC_SRC_PATH="../asset-transfer-secured-agreement"
	elif [ "$CC_NAME" = "ledger" ]; then
		echo $'\e[0;32m'asset-transfer-ledger-agreeement$'\e[0m' chaincode
		CC_SRC_PATH="../asset-transfer-ledger-queries"
	elif [ "$CC_NAME" = "private" ]; then
		echo $'\e[0;32m'asset-transfer-private-data$'\e[0m' chaincode
		CC_SRC_PATH="../asset-transfer-private-data"
	else
		echo The chaincode name ${CC_NAME} is not supported by this script
		echo Supported chaincode names are: basic, secured, and private
		exit 1
	fi

	echo "CC_SRC_PATH=$CC_SRC_PATH"
	# now see what language it is written in
	if [ "$CC_SRC_LANGUAGE" = "go" ]; then
		CC_SRC_PATH="$CC_SRC_PATH/chaincode-go/"
	elif [ "$CC_SRC_LANGUAGE" = "java" ]; then
		CC_SRC_PATH="$CC_SRC_PATH/chaincode-java/"
	elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
		CC_SRC_PATH="$CC_SRC_PATH/chaincode-javascript/"
	elif [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
		CC_SRC_PATH="$CC_SRC_PATH/chaincode-typescript/"
	fi

	# check that the language is available for the sample chaincode
	if [ ! -d "$CC_SRC_PATH" ]; then
		echo The smart contract language "$CC_SRC_LANGUAGE" is not yet available for
		echo the "$CC_NAME" sample smart contract
		exit 1
	fi
## Make sure that the path the chaincode exists if provided
elif [ ! -d "$CC_SRC_PATH" ]; then
	echo Path to chaincode does not exist. Please provide different path
	exit 1
fi

# do some language specific preparation to the chaincode before packaging
if [ "$CC_SRC_LANGUAGE" = "go" ]; then
		CC_RUNTIME_LANGUAGE=golang

	echo Vendoring Go dependencies at $CC_SRC_PATH
	pushd $CC_SRC_PATH
	GO111MODULE=on go mod vendor
	popd
	echo Finished vendoring Go dependencies

elif [ "$CC_SRC_LANGUAGE" = "java" ]; then
	CC_RUNTIME_LANGUAGE=java

	echo Compiling Java code ...
	pushd $CC_SRC_PATH
	./gradlew installDist
	popd
	echo Finished compiling Java code
	CC_SRC_PATH=$CC_SRC_PATH/build/install/$CC_NAME

elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
	CC_RUNTIME_LANGUAGE=node

elif [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
	CC_RUNTIME_LANGUAGE=node

	echo Compiling TypeScript code into JavaScript ...
	pushd $CC_SRC_PATH
	npm install
	npm run build
	popd
	echo Finished compiling TypeScript code into JavaScript

else
	echo The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script
	echo Supported chaincode languages are: go, java, javascript, and typescript
	exit 1
fi

INIT_REQUIRED="--init-required"
# check if the init fcn should be called
if [ "$CC_INIT_FCN" = "NA" ]; then
	INIT_REQUIRED=""
fi

if [ "$CC_END_POLICY" = "NA" ]; then
	CC_END_POLICY=""
else
	CC_END_POLICY="--signature-policy $CC_END_POLICY"
fi

if [ "$CC_COLL_CONFIG" = "NA" ]; then
	CC_COLL_CONFIG=""
else
	CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
fi


#if [ "$CC_INIT_FCN" = "NA" ]; then
#	INIT_REQUIRED=""
#fi

# import utils
. scripts/envVar.sh

# modified at 2020.9.8, due to unstable result of hostname -I
HOST_STR=$(hostname -I)
HOST_1="172.30.0.196"
HOST_2="172.30.0.59"
HOST_3="172.30.0.178"
HOST_4="172.30.0.80"
HOST_5="172.30.0.186"
HOST_6="172.30.0.74"

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


packageChaincode() {
	ORG=$1
	setGlobals $ORG
	set -x
	peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
	res=$?
	set +x
	cat log.txt

	verifyResult $res "Chaincode packaging on ${PEER_NAME} has failed"
	echo "===================== Chaincode is packaged on ${PEER_NAME} ===================== "
	echo
}

# installChaincode PEER ORG
installChaincode() {
	ORG=$1
	setGlobals $ORG
	set -x
	peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
	res=$?
	set +x
	cat log.txt

	verifyResult $res "Chaincode installation on ${PEER_NAME} has failed"
	echo "===================== Chaincode is installed on ${PEER_NAME} ===================== "
	echo
}

# queryInstalled PEER ORG
queryInstalled() {
	ORG=$1
	setGlobals $ORG
	set -x
	peer lifecycle chaincode queryinstalled >&log.txt
	res=$?
	set +x
	cat log.txt
	PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)

  verifyResult $res "Query installed on ${PEER_NAME} has failed"
	echo "===================== Query installed successful on ${PEER_NAME} on channel ===================== "
	echo
}


# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
	ORG=$1
	setGlobals $ORG
	set -x
	peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
	res=$?
	set +x
	cat log.txt

	verifyResult $res "Chaincode definition approved on ${PEER_NAME} on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode definition approved on ${PEER_NAME} on channel '$CHANNEL_NAME' ===================== "
	echo
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
	ORG=$1
	shift 1
	setGlobals $ORG

	echo "===================== Checking the commit readiness of the chaincode definition on ${PEER_NAME} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
	# we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
		sleep $DELAY
		echo "Attempting to check the commit readiness of the chaincode definition on ${PEER_NAME}.org${ORG}, Retry after $DELAY seconds."
		set -x
		peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt
		res=$?
		set +x
		let rc=0
		for var in "$@"; do
			grep "$var" log.txt &>/dev/null || let rc=1
		done
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	if test $rc -eq 0; then
		echo "===================== Checking the commit readiness of the chaincode definition successful on ${PEER_NAME} on channel '$CHANNEL_NAME' ===================== "
	else
		echo
		echo $'\e[1;31m'"!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Check commit readiness result on ${PEER_NAME} is INVALID !!!!!!!!!!!!!!!!"$'\e[0m'
		echo
		exit 1
	fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
	parsePeerConnectionParameters $@
	res=$?
	verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

	# while 'peer chaincode' command can get the orderer endpoint from the
	# peer (if join was successful), let's supply it directly as we know
	# it using the "-o" option
	set -x
	#peer lifecycle chaincode commit -o 129.63.205.110:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
	peer lifecycle chaincode commit -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt

	res=$?
	set +x
	cat log.txt

	verifyResult $res "Chaincode definition commit failed on ${PEER_NAME} on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
	echo
}

# queryCommitted ORG
queryCommitted() {
	ORG=$1
	setGlobals $ORG
	EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
	echo "===================== Querying chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
	# we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
		sleep $DELAY
		echo "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
		set -x
		peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
		res=$?
		set +x
		test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
		test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
		COUNTER=$(expr $COUNTER + 1)
	done
	echo
	cat log.txt

	if test $rc -eq 0; then
		echo "===================== Query chaincode definition successful on ${PEER_NAME} on channel '$CHANNEL_NAME' ===================== "
		echo
	else
		echo
		echo $'\e[1;31m'"!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query chaincode definition result on ${PEER_NAME} is INVALID !!!!!!!!!!!!!!!!"$'\e[0m'
		echo
		exit 1
	fi
}

chaincodeInvokeInit() {
	parsePeerConnectionParameters $@
	res=$?
	verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

	# while 'peer chaincode' command can get the orderer endpoint from the
	# peer (if join was successful), let's supply it directly as we know
	# it using the "-o" option
	echo "PEER_CONE_PARMS---$PEER_CONN_PARMS"

	set -x
	#fcn_call='{"function":"'${CC_INIT_FCN}'","Args":[]}'
	fcn_call='{"function":"InitLedger","Args":[]}'
	echo invoke fcn call:${fcn_call}
	#  remove this option "--isInit"
	peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS -c ${fcn_call} >&log.txt
	res=$?
	set +x
	cat log.txt
	verifyResult $res "Invoke execution on $PEERS failed "
	echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
	echo
}

chaincodeQuery() {
	ORG=$1
	setGlobals $ORG

	echo "===================== Querying on ${PEER_NAME}.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
	# we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
		sleep $DELAY
		echo "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
		set -x
		peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["GetAllAssets"]}' >&log.txt
		res=$?
		set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	echo
	cat log.txt
	if test $rc -eq 0; then
		echo "===================== Query successful on ${PEER_NAME} on channel '$CHANNEL_NAME' ===================== "
		echo
	else
		echo
		echo $'\e[1;31m'"!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query result on ${PEER_NAME} is INVALID !!!!!!!!!!!!!!!!"$'\e[0m'
		echo
		exit 1
	fi
}

# It is recommended that organizations only package a chaincode once, and then install the same package on every peer that belongs to their org.
# If a channel wants to ensure that each organization is running the same chaincode, one organization can package a chaincode
# and send it to other channel members out of band.
# Here we choose package the chaincode on peer0.org1.example.com
# after package, you need to scp the tar file to other servers
################################################################################################
export GODEBUG=netdns=go

# package chaincode
if [ "$HOST_IP" == "$HOST_1" ]; then
	packageChaincode 1
fi

## Install chaincode on UML (peer0.org1, peer1.org1, peer2.org1) and UW (peer0.org2, peer1.org2, peer2.org2)
if [ "$HOST_IP" == "$HOST_1" ]; then
	echo "Installing chaincode on peer0.org1..."
	installChaincode 1
elif [ "$HOST_IP" == "$HOST_2" ]; then
	echo "Installing chaincode on peer1.org1..."
	installChaincode 1
elif [ "$HOST_IP" == "$HOST_3" ]; then
	echo "Installing chaincode on peer0.org2..."
	installChaincode 1
elif [ "$HOST_IP" == "$HOST_4" ]; then
	echo "Installing chaincode on peer1.org2..."
	installChaincode 2
elif [ "$HOST_IP" == "$HOST_5" ]; then
	echo "Installing chaincode on peer1.org2..."
	installChaincode 2
elif [ "$HOST_IP" == "$HOST_6" ]; then
	echo "Installing chaincode on peer1.org2..."
	installChaincode 2
else
	echo "unknown host, not allow install chaincode."
fi

#############################################################################################
# approve a chaincode for an organization once, even if the org has multiple peers！！！
#############################################################################################
if [ "$HOST_IP" == "$HOST_1" -o "$HOST_IP" == "$HOST_2" -o "$HOST_IP" == "$HOST_3" ]; then
	## query whether the chaincode is installed
	queryInstalled 1
	# HOST_1 is peer0.org1.example.com
	if [ "$HOST_IP" == "$HOST_1" ]; then
		approveForMyOrg 1
	fi
	## check whether the chaincode definition is ready to be committed, expect org1 to have approved and org2 not to
	# checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": false"
	#checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": false"
	# queryCommitted 1

elif [ "$HOST_IP" == "$HOST_4" -o "$HOST_IP" == "$HOST_5" -o "$HOST_IP" == "$HOST_6" ]; then
	## approve the definition for org1
	queryInstalled 2
	# HOST_4 is peer0.org2.example.com
	if [ "$HOST_IP" == "$HOST_4" ]; then
		approveForMyOrg 2
	fi
	## check whether the chaincode definition is ready to be committed, expect them both to have approved
	#checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": true"
	# checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": true"
	# queryCommitted 2
else
	echo "unknown org peer in chaincode approving."
fi

## commit chaincode in deployCC_step2.sh


exit 0
