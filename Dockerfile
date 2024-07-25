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
RUN npm install --global yarn \
  # We can't use snap packages for Firefox inside a container, so we need to get Firefox+Geckodriver elsewhere
  && apt-get update \
  && apt-get install -y --no-install-recommends wget gnupg \
  && wget -q -O - "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x9BDB3D89CE49EC21" | apt-key add - \
  && wget -q -O - "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xA6DCF7707EBC211F" | apt-key add - \
  && echo "deb http://ppa.launchpad.net/mozillateam/ppa/ubuntu focal main" > /etc/apt/sources.list.d/mozillateam-ppa.list \
  && echo "Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001" > /etc/apt/preferences.d/mozilla-firefox \
  && apt-get update \
  && apt-get install --no-install-recommends -y firefox firefox-geckodriver \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


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
