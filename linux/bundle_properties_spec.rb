require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

context 'Bundle Properties' do

  # technically OSGI is around for quite some time and
  # one just need to add metadata to the manifest
  # The headers are somewhat overly detailed
  # http://www.liferaysavvy.com/2017/09/osgi-bundle-manifest-headers.html
  # at a minimum, the Export-Package: package_name;version="version_number" and the mandatory fields
  # https://www.ibm.com/support/knowledgecenter/en/SS7K4U_8.5.5/com.ibm.websphere.osgi.zseries.doc/ae/ra_bundle_mf.html
  # https://spring.io/blog/2008/02/18/creating-osgi-bundles/

  # this header can be automatically generated, usually via the Apache Felix Maven plugin (though generation of the MANIFEST.MF is not its direct purpose)
  # https://felix.apache.org/documentation/subprojects/apache-felix-maven-bundle-plugin-bnd.html
  tmp_path = '/tmp'
  jdbc_path = '/tmp'
  input_file = "#{tmp_path}/MANIFEST.MF"
  # not needed in CLASSPATH
  jar_version = '42.2.6'
  jdbc_jar = "postgresql-#{jar_version}.jar"
  # TODO: extract manifest from the jar
  # pushd #{tmp_path}
  # jar xvf '#{jdbc_path}/#{jdbc_jar}' META-INF/maven/org.postgresql/postgresql/pom.properties
  # inflated: META-INF/maven/org.postgresql/postgresql/pom.properties
  # grep -q 'version=#{jar_version}' 'META-INF/maven/org.postgresql/postgresql/pom.properties'
  # jar xvf '#{jdbc_path}/#{jdbc_jar}' META-INF/MANIFEST.MF
  # grep -q 'Bundle-Version: #{jar_version}'

  fixed_file = "#{tmp_path}/MANIFEST.MF.properties"
  # manifest text raw has tbl style formatting
  sample_data = <<-EOF
Manifest-Version: 1.0
Bnd-LastModified: 1560974407585
Build-Jdk: 1.8.0_151
Built-By: travis
Bundle-Activator: org.postgresql.osgi.PGBundleActivator
Bundle-Copyright: Copyright (c) 2003-2015, PostgreSQL Global Development
  Group
Bundle-Description: Java JDBC 4.2 (JRE 8+) driver for PostgreSQL databas
 e
Bundle-DocURL: https://jdbc.postgresql.org/
Bundle-License: https://jdbc.postgresql.org/about/license.html
Bundle-ManifestVersion: 2
Bundle-Name: PostgreSQL JDBC Driver JDBC42
Bundle-SymbolicName: org.postgresql.jdbc42
Bundle-Vendor: PostgreSQL Global Development Group
Bundle-Version: 42.2.6
Created-By: Apache Maven Bundle Plugin
Export-Package: org.postgresql;version="42.2.6";uses:="org.postgresql.co
 py,org.postgresql.fastpath,org.postgresql.jdbc,org.postgresql.largeobje
 ct,org.postgresql.replication,org.postgresql.util",org.postgresql.copy;
 version="42.2.6";uses:="org.postgresql,org.postgresql.core",org.postgre
 sql.core;version="42.2.6";uses:="javax.net,javax.net.ssl,org.postgresql
 ,org.postgresql.copy,org.postgresql.core.v3,org.postgresql.jdbc,org.pos
 tgresql.replication,org.postgresql.replication.fluent.logical,org.postg
 resql.replication.fluent.physical,org.postgresql.util",org.postgresql.c
 ore.v3;version="42.2.6";uses:="org.postgresql.copy,org.postgresql.core,
 org.postgresql.jdbc,org.postgresql.util",org.postgresql.core.v3.replica
 tion;version="42.2.6";uses:="org.postgresql.copy,org.postgresql.core,or
 g.postgresql.replication,org.postgresql.replication.fluent.logical,org.
 postgresql.replication.fluent.physical",org.postgresql.ds;version="42.2
 .6";uses:="javax.naming,javax.sql,org.postgresql.ds.common",org.postgre
 sql.ds.common;version="42.2.6";uses:="javax.naming,javax.naming.spi,jav
 ax.sql,org.postgresql,org.postgresql.jdbc",org.postgresql.fastpath;vers
 ion="42.2.6";uses:="org.postgresql.core",org.postgresql.geometric;versi
 on="42.2.6";uses:="org.postgresql.util",org.postgresql.gss;version="42.
 2.6";uses:="javax.security.auth.callback,org.postgresql.core",org.postg
 resql.hostchooser;version="42.2.6";uses:="org.postgresql.util",org.post
 gresql.jdbc;version="42.2.6";uses:="javax.xml.transform,org.postgresql,
 org.postgresql.copy,org.postgresql.core,org.postgresql.fastpath,org.pos
 tgresql.jdbc2,org.postgresql.largeobject,org.postgresql.replication,org
 .postgresql.util",org.postgresql.jdbc2;version="42.2.6",org.postgresql.
 jdbc2.optional;version="42.2.6";uses:="org.postgresql.ds",org.postgresq
 l.jdbc3;version="42.2.6";uses:="org.postgresql.ds",org.postgresql.jre8.
 sasl;version="42.2.6";uses:="org.postgresql.core,org.postgresql.util",o
 rg.postgresql.largeobject;version="42.2.6";uses:="org.postgresql.core,o
 rg.postgresql.fastpath",org.postgresql.osgi;version="42.2.6";uses:="jav
 ax.sql,org.osgi.framework,org.osgi.service.jdbc",org.postgresql.replica
 tion;version="42.2.6";uses:="org.postgresql.core,org.postgresql.replica
 tion.fluent",org.postgresql.replication.fluent;version="42.2.6";uses:="
 org.postgresql.core,org.postgresql.replication,org.postgresql.replicati
 on.fluent.logical,org.postgresql.replication.fluent.physical",org.postg
 resql.replication.fluent.logical;version="42.2.6";uses:="org.postgresql
 .core,org.postgresql.replication,org.postgresql.replication.fluent",org
 .postgresql.replication.fluent.physical;version="42.2.6";uses:="org.pos
 tgresql.core,org.postgresql.replication,org.postgresql.replication.flue
 nt",org.postgresql.ssl;version="42.2.6";uses:="javax.net.ssl,javax.secu
 rity.auth.callback,org.postgresql.core,org.postgresql.util",org.postgre
 sql.ssl.jdbc4;version="42.2.6";uses:="javax.net.ssl,org.postgresql.ssl,
 org.postgresql.util",org.postgresql.sspi;version="42.2.6";uses:="com.su
 n.jna,org.postgresql.core",org.postgresql.translation;version="42.2.6",
 org.postgresql.util;version="42.2.6";uses:="org.postgresql.core",org.po
 stgresql.xa;version="42.2.6";uses:="javax.naming,javax.sql,javax.transa
 ction.xa,org.postgresql.core,org.postgresql.ds,org.postgresql.ds.common
 "
Implementation-Title: PostgreSQL JDBC Driver - JDBC 4.2
Implementation-Vendor: PostgreSQL Global Development Group
Implementation-Vendor-Id: org.postgresql
Implementation-Version: 42.2.6
Import-Package: javax.sql,javax.transaction.xa,javax.naming,com.ongres.s
 cram.client;resolution:=optional,com.ongres.scram.common;resolution:=op
 tional,com.ongres.scram.common.exception;resolution:=optional,com.ongre
 s.scram.common.message;resolution:=optional,com.ongres.scram.common.str
 ingprep;resolution:=optional,com.sun.jna;resolution:=optional,com.sun.j
 na.platform.win32;resolution:=optional,com.sun.jna.ptr;resolution:=opti
 onal,com.sun.jna.win32;resolution:=optional,javax.crypto;resolution:=op
 tional,javax.crypto.spec;resolution:=optional,javax.naming.ldap;resolut
 ion:=optional,javax.naming.spi;resolution:=optional,javax.net;resolutio
 n:=optional,javax.net.ssl;resolution:=optional,javax.security.auth;reso
 lution:=optional,javax.security.auth.callback;resolution:=optional,java
 x.security.auth.login;resolution:=optional,javax.security.auth.x500;res
 olution:=optional,javax.xml.parsers;resolution:=optional,javax.xml.stre
 am;resolution:=optional,javax.xml.transform;resolution:=optional,javax.
 xml.transform.dom;resolution:=optional,javax.xml.transform.sax;resoluti
 on:=optional,javax.xml.transform.stax;resolution:=optional,javax.xml.tr
 ansform.stream;resolution:=optional,org.ietf.jgss;resolution:=optional,
 org.osgi.framework;resolution:=optional;version="[1.6,2)",org.osgi.serv
 ice.jdbc;resolution:=optional;version="[1.0,2)",org.w3c.dom;resolution:
 =optional,org.xml.sax;resolution:=optional,waffle.windows.auth;resoluti
 on:=optional,waffle.windows.auth.impl;resolution:=optional
Main-Class: org.postgresql.util.PGJDBCMain
Provide-Capability: osgi.service;effective:=active;objectClass="org.osgi
 .service.jdbc.DataSourceFactory"
Require-Capability: osgi.ee;filter:="(&(|(osgi.ee=J2SE)(osgi.ee=JavaSE))
 (version>=1.8))"
Specification-Title: JDBC
Specification-Vendor: Oracle Corporation
Specification-Version: 4.2
Tool: Bnd-2.4.0.201411031534

EOF
  before(:each) do
    $stderr.puts "Writing #{input_file}"
    file = File.open(input_file, 'w')
    file.puts sample_data
    file.close
    $stderr.puts "Converting #{input_file}"
    path = input_file;
    text = File.read(path);
    fixed_lines = [];
    text.gsub!(/\n  */, ''   )
    text.split(/\n/).each do |line|
      fixed_lines.push (line.gsub(/^  */, '' ))
    end
    $stderr.puts fixed_lines.join("\n")
    $stderr.puts "Writing #{fixed_file}"
    file = File.open(fixed_file, 'w')
    file.puts fixed_lines.join("\n")
    file.close

  end

  context 'Loading with Java' do
    class_name = 'TestProperties'
    sourcfile = "#{class_name}.java"
    source = <<-EOF
      import java.io.FileInputStream;
      import java.io.FileNotFoundException;
      import java.io.IOException;
      import java.util.Enumeration;
      import java.util.HashMap;
      import java.util.Map;
      import java.util.Properties;

      public class #{class_name} {
        private static final String fileName = "#{fixed_file}";
        public static void main(String[] argv) throws Exception {
          Properties propertiesObj = new Properties();
          Map<String, String> propertiesMap = new HashMap<>();
          try {
            propertiesObj.load(new FileInputStream(fileName));
            @SuppressWarnings("unchecked")
            Enumeration<String> propertyNames = (Enumeration<String>) propertiesObj.propertyNames();
            for (; propertyNames.hasMoreElements();) {
              String key = propertyNames.nextElement();
              String val = propertiesObj.get(key).toString();
              // System.out.println(String.format("Extracted: '%s' = '%s'", key, val));
              propertiesMap.put(key, val);
            }
          } catch (FileNotFoundException e) {
            System.err.println( String.format("Properties file was not found: '%s'", fileName));
            e.printStackTrace();
          } catch (IOException e) {
            System.err.println( String.format("Properties file is not readable: '%s'", fileName));
            e.printStackTrace();
          }
          String res = propertiesMap.get("Export-Package");
          System.out.println( String.format("Result: '%s'", res.substring(0,31)));
        }
      }

    EOF
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd '#{tmp_path}'
      echo '#{source}' > '#{sourcfile}'
      javac '#{sourcfile}'
      java '#{class_name}'
      1>/dev/null 2>/dev/null popd
    EOF

    ) do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
      its(:stdout) { should contain 'Result: org.postgresql;version="42.2.6"' }
    end
  end
  context 'Run Ruby in RVM session' do
    tmp_path = '/tmp'
    input_file = "#{tmp_path}/MANIFEST.MF"
    # see also
    # https://github.com/jnbt/java-properties
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd '#{tmp_path}'
      ruby  -e \\
      'fixed_lines = File.read("#{input_file}").gsub!(/\\r?\\n  */, "").split(/\\n/).each { |l| l.gsub!(/^  */, "" ) }
      properties = {}
      fixed_lines.each do |line|
        key,val = line.split /:\\s+/
        puts sprintf "%20s", key
        properties[key] =  val
      end
      '
      1>/dev/null 2>/dev/null popd

    EOF
    ) do
      its(:exit_status) { should eq 0 }
      # its(:stderr) { should be_empty }
      %w|
        Manifest-Version
        Bnd-LastModified
        Build-Jdk
        Built-By
        Bundle-Description
        Export-Package
        Specification-Title
        Specification-Vendor
        Specification-Version
      |.each do|key|
        its(:stdout) { should contain key[0..19] }
      end
    end
  end
end
