FROM ruby:3.3-alpine

RUN gem install rackup puma

WORKDIR /app
COPY interface-manager.rb .

RUN mkdir /data

CMD ["ruby","interface-manager.rb"]
