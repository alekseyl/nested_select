FROM ruby:3.4

WORKDIR /app

RUN gem install bundler

COPY lib/nested_select/version.rb /app/lib/nested_select/version.rb
COPY nested_select.gemspec /app/
COPY Gemfile* /app/
COPY Rakefile /app/

RUN bundle install