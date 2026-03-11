FROM ruby:3.3-alpine

RUN gem install sinatra

WORKDIR /app
COPY app.rb .

RUN mkdir /data

CMD ["ruby","app.rb"]
