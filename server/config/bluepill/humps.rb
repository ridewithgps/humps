rails_root = "/var/www/humps/current/server"
uni_path = "/var/www/humps/current/server/config"

require "#{rails_root}/config/bluepill/triggers.rb"

Bluepill.application("humps", :log_file => "#{rails_root}/log/bluepill.log") do |app|
  alert_email = "info@ridewithgps.com"
  app.working_dir = rails_root

  app.process("unicorn") do |process|
    process.pid_file = File.join(rails_root, 'tmp', 'pids', 'unicorn.pid')
    process.stdout = File.join(rails_root, 'log', 'unicorn.stdout.log')
    process.stderr = File.join(rails_root, 'log', 'unicorn.stderr.log')

    process.start_command = "bundle exec unicorn -Dc #{uni_path}/unicorn.rb -E production"
    process.stop_command = "kill -QUIT {{PID}}"
    process.restart_command = "kill -USR2 {{PID}}"

    process.uid = process.gid = 'deploy'
    #process.daemonize = true

    process.start_grace_time = 60.seconds
    process.stop_grace_time = 15.seconds
    process.restart_grace_time = 60.seconds
    process.checks :email_notifier, notify_on: [:unmonitored, :down, :starting, :stopping, :restarting], application: 'rwgps_production', process: 'unicorn', email: alert_email

    process.monitor_children do |child|
      child.stop_command = "kill -QUIT {{PID}}"
      child.stop_signals = [:quit, 30.seconds, :term, 5.seconds, :kill]
      child.checks :mem_usage, :every => 60.seconds, :below => 1000.megabytes, :times => [3,4]
      child.checks :cpu_usage, :every => 60.seconds, :below => 100, :times => [3,4], :fires => :stop
    end
  end
end
