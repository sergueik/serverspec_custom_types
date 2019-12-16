FROM ruby:2.3.3-alpine
# LABEL maintainer=""
ARG basedir="/serverspec"
ENV PACKAGES build-base \
    libcurl \
    libxml2-dev \
    libxslt-dev \
    libffi-dev \
    libmcrypt-dev \
    openssl
# NOTE - better to pass via -e argument to docker run:
# -e CONTAINER_NAME=test_container
ENV GEMS docker-api \
   ffi \
   inifile \
   psych \
   rake \
   rspec \
   rspec-core \
   rspec_junit_formatter \
   rspec-mocks \
   rspec-support \
   serverspec \
   specinfra

# NOTE: time consuming: adding the folling two gems increase build time by
# it also shortens dependency packages list but this saving is insigificant
ENV OPTIONAL_GEMS nokogiri yamllint

RUN apk add --update --no-cache $PACKAGES
RUN rm -rf /var/cache/apk/*
RUN apk add
RUN mkdir -p "${basedir}/spec/localhost"
# RUN gem install --no-rdoc --no-ri $GEMS $OPTIONAL_GEMS
RUN gem install --no-rdoc --no-ri $GEMS

ENV DOCKER_IMAGE serverspec-example
ADD "Rakefile" "${basedir}/Rakefile"
ADD "Dockerfile" "${basedir}/Dockerfile"
ADD "spec/spec_helper.rb" "${basedir}/spec/spec_helper.rb"
ADD "spec/docker_helper.rb" "${basedir}/spec/docker_helper.rb"

CMD ["rake", "spec"]
WORKDIR $basedir
