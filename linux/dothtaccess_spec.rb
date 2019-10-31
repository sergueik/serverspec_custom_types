require 'spec_helper'

# origin: http://activemq.apache.org/hello-world.html
# see also: https://github.com/fanlychie/activemq-samples/blob/master/activemq-quickstart/src/main/java/org/fanlychie/mq/Consumer.java


context 'Apache .htaccess' do
  webroot = '/var/www'
  dot_htaccess_contents = <<-EOF

Redirect 302 /main /main-index.html
RedirectMatch 301 /main* /index.html
# RedirectMatch 3001 /bad* /index.html
# typo in HTTP status would affect all URLs
# Redirect URL not valid for this status
  EOF

httpd_conf_contents = <<-EOF

ServerRoot "/etc/httpd"
Listen 80
Include conf.modules.d/*.conf
User apache
Group apache
ServerAdmin root@localhost
<Directory />
  AllowOverride none
  Require all denied
</Directory>
DocumentRoot "#{webroot}"
<Directory "#{webroot}">
  Options Indexes FollowSymLinks
  AllowOverride All
  Require all granted
</Directory>

<IfModule dir_module>
  DirectoryIndex index.html
</IfModule>

<Files ".ht*">
  Require all denied
</Files>

ErrorLog "logs/error_log"
LogLevel warn

<IfModule alias_module>
  ScriptAlias /cgi-bin/ "#{webroot}/cgi-bin/"
</IfModule>

<Directory "#{webroot}/cgi-bin">
  AllowOverride None
  Options None
  Require all granted
</Directory>

<IfModule mime_module>
  TypesConfig /etc/mime.types
  AddType application/x-compress .Z
  AddType application/x-gzip .gz .tgz
  AddType text/html .shtml
  AddOutputFilter INCLUDES .shtml
</IfModule>

AddDefaultCharset UTF-8

<IfModule mime_magic_module>
  MIMEMagicFile conf/magic
</IfModule>

EnableSendfile on

IncludeOptional conf.d/*.conf

EOF

  service = 'httpd'
  before(:each) do
    $stderr.puts "Writing '#{webroot}/.htaccess'"
    file = File.open("#{webroot}/.htaccess", 'w')
    file.puts dot_htaccess_contents
    file.close
    $stderr.puts "Writing '/etc/httpd/conf/httpd.conf'"
    file = File.open('/etc/httpd/conf/httpd.conf', 'w')
    file.puts httpd_conf_contents
    file.close
    Specinfra::Runner::run_command( "systemctl stop #{service} ; systemctl start #{service}")
  end
  {
    'bad'     => 'HTTP/1.1 404 Not Found',
    'main'    => 'HTTP/1.1 302 Found',
    'main123' => 'HTTP/1.1 301 Moved Permanently',
    'main$'   => 'HTTP/1.1 301 Moved Permanently',
    'main~'   => 'HTTP/1.1 301 Moved Permanently',
  }.each do |path,response|
    describe command(<<-EOF
      curl -I -k "http://localhost:80/#{path}"
    EOF
    ) do
      its(:stdout)  { should contain response }
    end
  end
end
