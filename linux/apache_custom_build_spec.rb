require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Apache configuration' do
  # apache built from source after
  # ./connfigure --prefix=$BASEDIR
  context 'basedir settings' do
    # nout counting binary files
    basedir = '/opt/apache1'
    %w|
       bin/envvars
       bin/apachectl
       bin/apxs
       bin/envvars-std
       bin/apu-1-config
       bin/apr-1-config
       conf/original/httpd.conf
       conf/original/extra/httpd-ssl.conf
       conf/original/extra/httpd-dav.conf
       conf/original/extra/httpd-autoindex.conf
       conf/original/extra/httpd-ssl.conf
       conf/original/extra/httpd-vhosts.conf
      |.each do |relative_path|
      describe file("#{basedir}/#{relative_path}") do
        its(:content) { should match /(\"|\'|\/)#{Regexp.escape(basedir)}\/\S+/ }
      end
    end
  end
end
