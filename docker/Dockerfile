FROM ruby:2.3.3-alpine
# LABEL maintainer=""
ARG app_jar="example.basic.jar"
ARG basedir="/serverspec"
ARG sampledir="${basedir}/tmp"
ARG packages="build-base libcurl libxml2-dev libxslt-dev libffi-dev libmcrypt-dev openssl jq libxml2-utils"
# for jq and xmllint

ENV DOCKER_IMAGE serverspec-example
# NOTE - also possibe to pass via -e argument to docker run:
# -e CONTAINER_NAME=test_container
ARG gems="docker-api ffi inifile psych rake rspec rspec-core rspec_junit_formatter rspec-mocks rspec-support serverspec specinfra"

# NOTE: compiling native extensions is quite time consuming:
# adding the folling two gems increase build time by 5 to 10 minute
# it shortens dependency packages list but isn't sigificant
# ARG optional_gems="nokogiri yamllint"
ARG optional_gems=""

RUN apk add --update --no-cache $packages; rm -rf /var/cache/apk/*; apk add
RUN gem install --no-rdoc --no-ri $gems $optional_gems

RUN mkdir -p $sampledir
RUN echo '{"foo":"bar"}' > "${sampledir}/example.json"
RUN echo '<?xml version="1.0"?><Server port="8005" shutdown="SHUTDOWN"></Server>' >"${sampledir}/example.xml"

ADD "data.json" "${sampledir}/data.json"
ADD "data.xml" "${sampledir}/data.xml"

RUN mkdir -p "${basedir}/spec/localhost"

ADD "Rakefile" "${basedir}/Rakefile"
ADD "Dockerfile" "${basedir}/Dockerfile"
ADD "spec/spec_helper.rb" "${basedir}/spec/spec_helper.rb"
ADD "spec/docker_helper.rb" "${basedir}/spec/docker_helper.rb"



WORKDIR $basedir
CMD ["rake", "spec"]
