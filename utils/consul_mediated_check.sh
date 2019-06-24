#!/bin/sh
# https://www.consul.io/docs/commands/exec.html
# see also https://blog.froese.org/2014/12/12/abusing-consul-exec-just-because/
# intentionally formatted as a copy-paste-able one-liner 
# to be ready for user through e.g.  post-jumpbox ssh console
# assuming the whole cluster belongs to the same domain and filtering the outputby domain suffix.

#
# example 1
LEADER=$(hostname -f); CONSUL_HTTP_SSL=true; /usr/local/bin/consul exec -http-addr https://$LEADER:8543 hostname -f | grep $(hostname -d )
# example  2
VERSION_BUILD='41'; PACKAGE='tomcat'; LEADER=$(hostname -f); CONSUL_HTTP_SSL=true; /usr/local/bin/consul exec -http-addr https://$LEADER:8543 \(puppet resource "${PACKAGE}" | grep -Po "'[0-9].*'" \) \&\& hostname -f | grep $(hostname -d ) | grep -v $VERSION_BUILD
# example 3
LEADER=$(hostname -f); CONSUL_HTTP_SSL=true;/usr/local/bin/consul exec -http-addr https://$LEADER:8543 rpm-qa \| grep "${PACKAGE}" \; hostname -f | grep $(hostname -d )
# example 4
LEADER=$(hostname -f); CONSUL_HTTP_SSL=true;/usr/local/bin/consul exec -http-addr https://$LEADER:8543 jq -E '.acl_token' \< '/etc/consul.d/cofig.json' \|\| hostname -f | grep $(hostname -d )
