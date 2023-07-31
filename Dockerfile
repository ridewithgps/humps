# Dockerfile

FROM ruby:2.7.6

ENV ROOTDIR=/var/www/humps/current
ENV WORKDIR=$ROOTDIR/server
COPY . $ROOTDIR
WORKDIR $WORKDIR
RUN gem install bundler:2.4.17
RUN cd $WORKDIR;bundle install
RUN mkdir -p $WORKDIR/tmp/pids $WORKDIR/log

VOLUME /var/gisdata
EXPOSE 4002

ENTRYPOINT bundle exec unicorn -c $WORKDIR/config/unicorn.rb -E production
