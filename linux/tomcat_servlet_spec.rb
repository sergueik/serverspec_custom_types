require 'spec_helper'
require 'fileutils'

context 'Tomcat Servlet Test' do
  catalina_home = '/usr/share/tomcat'
  app_path = "#{catalina_home}/webapps/basic"
  webxml_file = "#{app_path}/WEB-INF/web.xml"
  # NOTE: indent sensitive (cured with strip)
  webxml_data = <<-EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <web-app xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://java.sun.com/xml/ns/javaee" xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd" version="3.0">
      <servlet>
        <servlet-name>basicServlet</servlet-name>
        <servlet-class>sample.Basic</servlet-class>
      </servlet>
      <servlet-mapping>
        <servlet-name>basicServlet</servlet-name>
        <url-pattern>/hello</url-pattern>
      </servlet-mapping>
    </web-app>
  EOF
  source_file = "#{app_path}/WEB-INF/sample/Basic.java"
  source_data = <<-EOF
    package sample;

    import javax.servlet.ServletException;
    import javax.servlet.http.HttpServlet;
    import javax.servlet.http.HttpServletRequest;
    import javax.servlet.http.HttpServletResponse;
    import java.io.IOException;
    import java.io.PrintWriter;

    public class Basic extends HttpServlet
    {
      protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        PrintWriter printWriter = resp.getWriter();
        printWriter.print("<h1> Hello world </h1>");
      }
    }

  EOF
  before(:all) do
    FileUtils.mkdir_p "#{app_path}/WEB-INF/sample"
    FileUtils.mkdir_p "#{app_path}/WEB-INF/classes"
    $stderr.puts "Writing #{webxml_file}"
    file = File.open(webxml_file, 'w')
    file.puts webxml_data.strip
    file.close
    $stderr.puts "Writing #{source_file}"
    file = File.open(source_file, 'w')
    file.puts source_data
    file.close
    $stderr.puts "Compiling #{source_file}"
    Specinfra::Runner::run_command( <<-EOF
      #{catalina_home}/bin/catalina.sh stop
      pushd "#{app_path}/WEB-INF/sample"
      rm -fr "#{app_path}/WEB-INF/classes/sample/*"
      javac -cp #{catalina_home}/lib/servlet-api.jar -d classes #{source_file}
      cat /dev/null > #{catalina_home}/logs/catalina.out
      #{catalina_home}/bin/catalina.sh start
      sleep 30
      EOF
    )

  end

  context 'Execution' do
    describe command(<<-EOF
      grep 'Deploying web application directory' "#{catalina_home}/logs/catalina.out" | grep 'webapps/basic'
    EOF
    ) do
      its(:stdout) { is_expected.to contain 'webapps/basic' }
      its(:stderr) { is_expected.to be_empty  }
      its(:exit_status) { is_expected.to eq 0 }
    end
    describe file("#{catalina_home}/logs/catalina.out") do
      its(:content) { is_expected.to contain 'has finished' }
    end

    describe command(<<-EOF
      curl --silent http://localhost:8080/basic/hello
    EOF
    ) do
      its(:stdout) { is_expected.to contain '<h1> Hello world </h1>' }
      its(:stderr) { is_expected.to be_empty }
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { should_not contain 'HTTP Status 500' }
    end
  end
end
