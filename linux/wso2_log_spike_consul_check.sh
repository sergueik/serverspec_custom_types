#!/bin/sh

# consul DNS aware application error spike inventory snippet
# NOTE: this is a draft of the script used in some real environment
TIMESTAMP_PART=$(date +%D|sed 's|/|-|g')
TIMESTAMP_PART=$(date +%m-%d)
export CONSUL_LEADER=$(hostname -f )
export APP='worker'
# consul typically names the application nodes by the hoster / monitored application running there
export NODENAME=$APP
export PROTOCOL='https'
export PORT='8543'

PATH=$PATH:/usr/local/bin
consul exec -http-addr $PROTOCOL:/$CONSUL_LEADER/:$PORT \
\( test -e /opt/wso2/apim/$APP \&\& -grep -i ' ERROR {[a-z0-9.-]*}' /opt/wso2/apim/$APP/repository/logs/wso2carbon.log \| grep $TODAY \|wc \) | grep $NODENAME

# will collect error spike inventory
# in the format:
# worker-0.consul.domain 10
# worker-1.consul.domain 20
# worker-2.consul.domain 40
# ...
