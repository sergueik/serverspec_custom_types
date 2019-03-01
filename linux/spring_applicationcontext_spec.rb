require 'spec_helper'

$DEBUG = (ENV.fetch('DEBUG', false) =~ (/^(true|t|yes|y|1)$/i))

# origin: https://stackoverflow.com/questions/28414234/where-can-i-find-the-example-applicationcontext-xml-file/28418012

context 'Example applicationContext.xml file spec' do

  context 'RabbitMQ configuration' do
    # origin: https://github.com/ndpar/rabbitmq-spring-demo/blob/master/src/main/resources/applicationContext.xml

    applicationcontext_datafile = '/tmp/applicationContext.xml'
    applicationcontext_content = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
      <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:context="http://www.springframework.org/schema/context" xmlns:rabbit="http://www.springframework.org/schema/rabbit" xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.2.xsd        http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-3.2.xsd        http://www.springframework.org/schema/rabbit http://www.springframework.org/schema/rabbit/spring-rabbit-1.0.xsd">
        <!-- Spring configuration -->
        <context:component-scan base-package="com.ndpar"/>
        <context:mbean-export default-domain="com.ndpar.rabbitmq"/>
        <!-- RabbitMQ common configuration -->
        <rabbit:connection-factory id="connectionFactory"/>
        <rabbit:template id="amqpTemplate" connection-factory="connectionFactory"/>
        <rabbit:admin connection-factory="connectionFactory"/>
        <!-- Queues -->
        <rabbit:queue id="springQueue" name="spring.queue" auto-delete="true" durable="false"/>
        <rabbit:listener-container connection-factory="connectionFactory">
          <rabbit:listener queues="springQueue" ref="messageListener"/>
        </rabbit:listener-container>
        <bean id="messageListener" class="com.ndpar.spring.rabbitmq.MessageHandler"/>
        <!-- Bindings -->
        <rabbit:fanout-exchange name="amq.fanout">
          <rabbit:bindings>
            <rabbit:binding queue="springQueue"/>
          </rabbit:bindings>
        </rabbit:fanout-exchange>
      </beans>
    EOF
    applicationcontext_content.gsub!(/\$/, '\\$')
    before(:each) do
      $stderr.puts "writing sample rabbitMQ applicationContext.xml in #{applicationcontext_datafile}"
      Specinfra::Runner::run_command( <<-EOF
        # no space at beginning of the document is critical for xml
        cat<<DATA|tee #{applicationcontext_datafile}
#{applicationcontext_content}
DATA
      EOF
      )
      # https://spring.io/guides/gs/messaging-rabbitmq/
      end
      describe command(<<-EOF
        xmllint --xpath '//*[local-name()="listener-container"][@connection-factory="connectionFactory"]/*[local-name()="listener"][@ref="messageListener"]/@queues' '#{applicationcontext_datafile}'
      EOF
      ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should contain 'queues="springQueue"' }
    end
  end
  context 'MongoDB configuration' do
    # origin: https://github.com/spring-projects/spring-data-mongodb/blob/master/spring-data-mongodb-cross-store/src/test/resources/META-INF/spring/applicationContext.xml
    applicationcontext_datafile = '/tmp/applicationContext.xml'
    applicationcontext_content = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
      <beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tx="http://www.springframework.org/schema/tx" xmlns:jdbc="http://www.springframework.org/schema/jdbc" xmlns:context="http://www.springframework.org/schema/context" xmlns:mongo="http://www.springframework.org/schema/data/mongo" xsi:schemaLocation="http://www.springframework.org/schema/data/mongo http://www.springframework.org/schema/data/mongo/spring-mongo.xsd   http://www.springframework.org/schema/jdbc http://www.springframework.org/schema/jdbc/spring-jdbc-3.0.xsd   http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd   http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx-3.0.xsd   http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-3.0.xsd">
        <context:spring-configured/>
        <context:component-scan base-package="org.springframework.persistence.mongodb.test">
          <context:exclude-filter expression="org.springframework.stereotype.Controller" type="annotation"/>
        </context:component-scan>
        <mongo:mapping-converter/>
        <!--  Mongo config -->
        <bean id="mongoClient" class="org.springframework.data.mongodb.core.MongoClientFactoryBean">
          <property name="host" value="localhost"/>
          <property name="port" value="27017"/>
        </bean>
        <bean id="mongoDbFactory" class="org.springframework.data.mongodb.core.SimpleMongoDbFactory">
          <constructor-arg name="mongoClient" ref="mongoClient"/>
          <constructor-arg name="databaseName" value="database"/>
        </bean>
        <bean id="mongoTemplate" class="org.springframework.data.mongodb.core.MongoTemplate">
          <constructor-arg name="mongoDbFactory" ref="mongoDbFactory"/>
          <constructor-arg name="mongoConverter" ref="mappingConverter"/>
        </bean>
        <bean class="org.springframework.data.mongodb.core.MongoExceptionTranslator"/>
        <!--  Mongo aspect config -->
        <bean class="org.springframework.data.mongodb.crossstore.MongoDocumentBacking" factory-method="aspectOf">
          <property name="changeSetPersister" ref="mongoChangeSetPersister"/>
        </bean>
        <bean id="mongoChangeSetPersister" class="org.springframework.data.mongodb.crossstore.MongoChangeSetPersister">
          <property name="mongoTemplate" ref="mongoTemplate"/>
          <property name="entityManagerFactory" ref="entityManagerFactory"/>
        </bean>
        <jdbc:embedded-database id="dataSource" type="HSQL">
        </jdbc:embedded-database>
        <bean id="transactionManager" class="org.springframework.orm.jpa.JpaTransactionManager">
          <property name="entityManagerFactory" ref="entityManagerFactory"/>
        </bean>
        <tx:annotation-driven mode="aspectj" transaction-manager="transactionManager"/>
        <bean class="org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean" id="entityManagerFactory">
          <property name="persistenceUnitName" value="test"/>
          <property name="dataSource" ref="dataSource"/>
          <property name="jpaVendorAdapter">
            <bean class="org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter">
              <property name="showSql" value="true"/>
              <property name="generateDdl" value="true"/>
              <property name="databasePlatform" value="org.hibernate.dialect.HSQLDialect"/>
            </bean>
          </property>
        </bean>
      </beans>
    EOF
    applicationcontext_content.gsub!(/\$/, '\\$')
    before(:each) do
      $stderr.puts "writing sample rabbitMQ applicationContext.xml in #{applicationcontext_datafile}"
      Specinfra::Runner::run_command( <<-EOF
        # no space at beginning of the document is critical for xml
        cat<<DATA|tee #{applicationcontext_datafile}
#{applicationcontext_content}
DATA
      EOF
      )
      # https://spring.io/guides/gs/messaging-rabbitmq/
      end
      describe command(<<-EOF
        xmllint --xpath '//*[local-name()="bean"][@class="org.springframework.data.mongodb.core.SimpleMongoDbFactory"]/*[local-name()="constructor-arg"][@name="databaseName"]/@value' '#{applicationcontext_datafile}'
      EOF
      ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should contain 'value="database"' }
    end

  end
end