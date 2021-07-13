# this file is used to solve the problem caused by docker name resolution
# execute by running "sudo ./dns_6host.sh" before deployment
# so that following mappings can be written into system file "/etc/hosts"
##########################################################################
echo "54.210.204.251	orderer.example.com" >> /etc/hosts
echo "107.22.48.133	peer0.org1.example.com" >> /etc/hosts
echo "54.175.11.179	peer1.org1.example.com" >> /etc/hosts
echo "54.85.126.114	peer2.org1.example.com" >> /etc/hosts
echo "54.197.127.36	peer0.org2.example.com" >> /etc/hosts
echo "3.92.185.56 peer1.org2.example.com" >> /etc/hosts
echo "54.86.220.113	peer2.org2.example.com" >> /etc/hosts
