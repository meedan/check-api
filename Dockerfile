FROM ruby
MAINTAINER Karim Ratib <karim@meedan.com>

RUN apt-get update -qq && apt-get install -y vim libpq-dev nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root and tini for signal handling
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 \
  && curl -o /usr/local/bin/tini -fSL "https://github.com/krallin/tini/releases/download/v0.9.0/tini" \
  && curl -o /usr/local/bin/tini.asc -fSL "https://github.com/krallin/tini/releases/download/v0.9.0/tini.asc" \
  && gpg --verify /usr/local/bin/tini.asc \
  && rm /usr/local/bin/tini.asc \
  && chmod +x /usr/local/bin/tini

# install our app
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile Gemfile.lock /app/
RUN gem install bundler && bundle install --jobs 20 --retry 5
COPY . /app

# the Rails stage can be overridden from the caller
ENV RAILS_ENV development

# startup
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
EXPOSE 3000
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
