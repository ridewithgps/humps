# Dockerfile

FROM ruby:2.7.4

ENV ROOTDIR=/var/www/humps/current
ENV WORKDIR=$ROOTDIR/server
COPY . $ROOTDIR
WORKDIR $WORKDIR
RUN gem install bundler:1.16.2
RUN cd $WORKDIR;bundle install
RUN mkdir -p $WORKDIR/tmp/pids $WORKDIR/log

VOLUME /var/gisdata
EXPOSE 4002

ENTRYPOINT bundle exec unicorn -c $WORKDIR/config/unicorn.rb -E production
