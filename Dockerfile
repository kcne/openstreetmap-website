FROM debian:12.6

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages then clean up to minimize image size
RUN apt-get update \
  && apt-get install --no-install-recommends -y \
  build-essential \
  curl \
  default-jre-headless \
  file \
  git-core \
  gpg-agent \
  libarchive-dev \
  libffi-dev \
  libgd-dev \
  libpq-dev \
  libsasl2-dev \
  libvips-dev \
  libxml2-dev \
  libxslt1-dev \
  libyaml-dev \
  locales \
  postgresql-client \
  ruby \
  ruby-dev \
  ruby-bundler \
  software-properties-common \
  tzdata \
  unzip \
  nodejs \
  npm

# Install yarn globally
RUN npm install --global yarn

# Install geckodriver and firefox
RUN apt-get update                             \
  && apt-get install -y --no-install-recommends \
  ca-certificates curl firefox-esr           \
  && curl -L https://github.com/mozilla/geckodriver/releases/download/v0.34.0/geckodriver-v0.34.0-linux64.tar.gz | tar xz -C /usr/local/bin

# Install compatible Osmosis to help users import sample data in a new instance
RUN curl -OL https://github.com/openstreetmap/osmosis/releases/download/0.47.2/osmosis-0.47.2.tgz \
  && tar -C /usr/local -xzf osmosis-0.47.2.tgz

ENV DEBIAN_FRONTEND=dialog

# Setup app location
RUN mkdir -p /app
WORKDIR /app

# Install Ruby packages
ADD Gemfile Gemfile.lock /app/
RUN bundle install

# Install NodeJS packages using yarn
ADD package.json yarn.lock /app/
ADD bin/yarn /app/bin/
RUN bundle exec bin/yarn install
