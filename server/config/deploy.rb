require 'capistrano'

default_run_options[:pty] = true

set :repository,  "git@github.com:ridewithgps/humps.git"
set :scm, :git
set :deploy_via, :remote_cache
#use our local ssh key, not server.  no need to manage
#a bunch of server keys in github
ssh_options[:forward_agent] = true

set (:deploy_to) { "/var/www/#{application}" }

role :app, "bruno", "fiona"
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
    restart
  end

  desc "Restart application"
  task :restart, :roles => :app, :except => { :no_release => true } do
    unicorn.restart
  end
end
