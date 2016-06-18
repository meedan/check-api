FROM ruby
MAINTAINER Karim Ratib <karim@meedan.com>

RUN apt-get update -qq && apt-get install -y vim libpq-dev nodejs

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile Gemfile.lock /app/
RUN gem install bundler && bundle install --jobs 20 --retry 5

COPY . /app

EXPOSE 3000
ENV RAILS_ENV development

ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server", "-b", "0.0.0.0"]
