FROM ruby:3.3.3

ENV ROOTDIR=/var/www/humps/current
ENV WORKDIR=$ROOTDIR/server
COPY . $ROOTDIR
WORKDIR $WORKDIR
RUN gem install bundler:2.5.14
RUN cd $WORKDIR;bundle install
RUN mkdir -p /tmp/pids $WORKDIR/log

VOLUME /var/gisdata
EXPOSE 4002

ENTRYPOINT bundle exec unicorn -c $WORKDIR/config/unicorn.rb -E production
