require 'spec_helper'
require 'find'

$DEBUG = (ENV.fetch('DEBUG', false) =~ (/^(true|t|yes|y|1)$/i))

# https://serverfault.com/questions/48109/how-to-find-files-with-incorrect-permissions-on-unix
context 'Springboot Jar contents scan' do
  jar_path = "/home/#{ENV.fetch('USER')}/src/springboot_study/basic-mysql/target"
  jar_filename = 'example.mysql.jar'
  
  # NOTE: when parenthesis omitted,
  # unexpected keyword_do_block, expecting end-of-input
  # syntax error, unexpected keyword_do_block, expecting keyword_end
 
  describe command( <<-EOF
    jar tvf '#{jar_path}/#{jar_filename}' 2>&1 | grep '/$' | awk '{print $NF}'
  EOF
  ) do
    %w|
      org/springframework/
      org/springframework/boot/
      org/springframework/boot/loader/
      org/springframework/boot/loader/data/
      org/springframework/boot/loader/jar/
      org/springframework/boot/loader/archive/
      org/springframework/boot/loader/util/
      BOOT-INF/lib/
    |.each do |folder_name|
      its(:stdout) {  should contain folder_name }
    end
  end

  field = 3
  describe command  "jar tvf '#{jar_path}/#{jar_filename}' 2>&1 | grep 'BOOT-INF/lib' | cut -d '/' -f #{field} | sed 's|\\-[0-9][0-9.]*\\(RELEASE\\)*\\(Final\\)*\\.jar||g' " do 
    %w|
      antlr
      aspectjweaver
      byte-buddy
      classmate
      dom4j
      hibernate-commons-annotations
      hibernate-core
      hibernate-validator
      HikariCP
      jackson-annotations
      jackson-core
      jackson-databind
      jackson-datatype-jdk8
      jackson-datatype-jsr310
      jackson-module-parameter-names
      jandex
      javassist-3.23.1-GA.jar
      javax.activation-api
      javax.annotation-api
      javax.persistence-api
      javax.transaction-api
      jaxb-api
      jboss-logging
      jul-to-slf4j
      log4j-api
      log4j-to-slf4j
      logback-classic
      logback-core
      mysql-connector-java
      slf4j-api
      snakeyaml
      spring-aop
      spring-aspects
      spring-beans
      spring-boot
      spring-boot-autoconfigure
      spring-boot-starter
      spring-boot-starter-aop
      spring-boot-starter-data-jpa
      spring-boot-starter-jdbc
      spring-boot-starter-json
      spring-boot-starter-logging
      spring-boot-starter-tomcat
      spring-boot-starter-validation
      spring-boot-starter-web
      spring-context
      spring-core
      spring-data-commons
      spring-data-jpa
      spring-expression
      spring-jcl
      spring-jdbc
      spring-orm
      spring-tx
      spring-web
      spring-webmvc
      tomcat-embed-core
      tomcat-embed-el
      tomcat-embed-websocket
      validation-api
   |.each do |jar_name|
     its(:stdout) {  should contain jar_name }
   end
 end
end
