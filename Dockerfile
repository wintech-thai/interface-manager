FROM ruby:3.3-alpine

RUN gem install sinatra rackup puma --no-document

WORKDIR /app
COPY interface-manager.rb .

RUN mkdir /data

CMD ["ruby","interface-manager.rb"]
