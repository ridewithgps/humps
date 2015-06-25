require 'capistrano'

default_run_options[:pty] = true

set :repository,  "git@github.com:ridewithgps/humps.git"
set :scm, :git
set :deploy_via, :remote_cache
set :normalize_asset_timestamps, false
#use our local ssh key, not server.  no need to manage
#a bunch of server keys in github
ssh_options[:forward_agent] = true

set (:deploy_to) { "/var/www/#{application}" }

role :app, "kona", "bailey"
set :application, 'humps'
set :user, 'deploy'
set :use_sudo, false
set :keep_releases, 5
set :branch, 'master'

def run_local cmd
  puts %[  * executing locally "#{cmd}"]
  `#{cmd}`
end

before :deploy do
end

after :deploy do
  deploy.cleanup
end

after "deploy:setup" do
  #ensure proper directory structure is created
  %w{/log /tmp /tmp/pids /vendor /vendor/bundle}.each do |file|
    run "mkdir -p #{shared_path}#{file}"
  end
end

after "deploy:update_code" do
  %w{/log /tmp /vendor}.each do |file|
    run "ln -nfs #{shared_path}#{file} #{release_path}/server#{file}"
  end
end

namespace :bluepill do
  task :stop, :roles => :app, :on_error => :continue do
    run 'bluepill humps quit --no-privilege'
  end

  task :start, :roles => :app do
    run "bluepill load #{current_path}/server/config/bluepill/humps.rb --no-privilege"
  end
end

namespace :unicorn do
  desc 'Stop unicorn'
  task :stop, :roles => :app do
    run "bluepill humps stop unicorn --no-privilege"
  end

  task :start, :roles => :app do
    run "bluepill humps start unicorn --no-privilege"
  end

  task :restart, :roles => :app do
    run "bluepill humps restart unicorn --no-privilege"
  end
end

namespace :deploy do
  desc "'nuff said"
  task :default do
    update
    bundle_install
    restart
  end

  task :bundle_install, :roles => [:app] do
    # using some ideas from https://github.com/carlhuda/bundler/blob/master/lib/bundler/deployment.rb
    bundle_flags = "--deployment --quiet"
    bundle_dir = File.join(fetch(:shared_path), 'vendor', 'bundle')
    args = ["--path #{bundle_dir}"]
    args << "--without development test"
    args << bundle_flags
    # before we use '--without development test' need to make sure
    # jenkins can install test gems. once we use the without i think
    # we can remove the RAILS_ENV check in Gemfile
    run "cd #{release_path} && bundle install #{args.join(' ')}"
  end

  desc "Restart application"
  task :restart, :roles => :app, :except => { :no_release => true } do
    unicorn.restart
  end

  task :bundle_install do
    # using some ideas from https://github.com/carlhuda/bundler/blob/master/lib/bundler/deployment.rb
    bundle_flags = "--deployment --quiet"
    bundle_dir = File.join(fetch(:shared_path), 'vendor', 'bundle')
    args = ["--path #{bundle_dir}"]
    args << "--without development test"
    args << bundle_flags
    # before we use '--without development test' need to make sure
    # jenkins can install test gems. once we use the without i think
    # we can remove the RAILS_ENV check in Gemfile
    run "cd #{current_path}/server && bundle install #{args.join(' ')}"
  end
end
