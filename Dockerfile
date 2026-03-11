FROM ruby:3.3-alpine

RUN gem install sinatra --no-document

WORKDIR /app
COPY iface-manager.rb .

RUN mkdir /data

CMD ["ruby","iface-manager.rb"]
