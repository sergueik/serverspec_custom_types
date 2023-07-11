require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

context 'SAX HTML tests' do
  haproxy_home_path = '/etc/haproxy'
  haproxy_config = 'haproxy.cfg'
  config_file = "#{haproxy_home_path}/#{haproxy_config}"
  tmp_path = '/tmp'
  # fragment of real haproxy configuration file
  # https://chase-seibert.github.io/blog/2011/02/26/haproxy-quickstart-w-full-example-config-file.html
  config_file = "#{tmp_path}/#{haproxy_config}"

  config_data = <<-EOF
    default_backend www

backend www
   balance roundrobin
   server www1 www1 check port 80
   server www2 www2 check port 80
   server www3 www3 check port 80
   # provide a maintenance page functionality, only used when all other servers are down
   server load1 localhost:8080 backup

backend static
   # for static media, connections are cheap, plus the client is very likely to request multiple files
   # so, keep the connection open (KeepAlive is the default)
   balance roundrobin
   server media1 media1 check port 80
   server media2 media2 check port 80

listen stats :1936
   mode http
   stats enable
   stats scope http
   stats scope www
   stats scope static
   stats scope static_httpclose
   stats realm Haproxy\ Statistics
   stats uri /
   stats auth haproxy:YOURPASSWORDHERE

  EOF
  before(:each) do
    $stderr.puts "Writing #{config_file}"
    file = File.open(config_file, 'w')
    file.puts config_data
    file.close
  end
  backend_alias = 'www'
  # NOTE: the following uses a simplified sed condition only valid for this exercise
  # and needed to consider for non-compact haproxy configuration with blank lines
  # https://stackoverflow.com/questions/45991100/sed-substitution-with-negative-lookahead-regex
  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd '#{tmp_path}'
    BACKEND='#{backend_alias}'
    sed -n "/^ *backend $BACKEND/,/^ *$/p" '#{config_file}'
    sed -n "/^ *backend $BACKEND/,/^ *backend [^w]/p" '#{config_file}'
    1>/dev/null 2>/dev/null popd
  EOF

  ) do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should be_empty }
    %w|www1 www2 www3|.each do |server|
      line = "server #{server} #{server} check port 80"
      its(:stdout) { should contain line }
    end
  end
end

