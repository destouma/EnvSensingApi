FROM ruby:2.7.1
# Debian buster is EOL and its packages moved to archive.debian.org (stopgap until the Ruby/base image upgrade)
RUN sed -i -e 's|deb.debian.org|archive.debian.org|g' -e 's|security.debian.org|archive.debian.org|g' -e '/buster-updates/d' /etc/apt/sources.list
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
# Set an environment variable where the Rails app is installed to inside of Docker image
ENV RAILS_ROOT /var/www/app_name
RUN mkdir -p $RAILS_ROOT
# Set working directory
WORKDIR $RAILS_ROOT
# Setting env up
ENV RAILS_ENV='production'
ENV RACK_ENV='production'
# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
ENV BUNDLER_VERSION 2.3.27
RUN gem install bundler  -v 2.3.27
RUN bundle install
# Adding project files
COPY . .
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]