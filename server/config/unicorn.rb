worker_processes 2

stderr_path File.join(File.dirname(__FILE__), '../log/unicorn.stderr.log')
stdout_path File.join(File.dirname(__FILE__), '../log/unicorn.stdout.log')
preload_app true

# Restart any workers that haven't responded in 30 seconds
timeout 40

# Listen on a Unix data socket
#listen '/home/kingcu/ridewithgps/tmp/sockets/unicorn.sock', :backlog => 1024
listen '0.0.0.0:4002', :tcp_nopush => true, :backlog => 1024

pid File.join("/var/run/humps/humps-unicorn.pid")

before_fork do |server, worker|
  # This allows a new master process to incrementally
  # phase out the old master process with SIGTTOU to avoid a
  # thundering herd (especially in the "preload_app false" case)
  # when doing a transparent upgrade.  The last worker spawned
  # will then kill off the old master process with a SIGQUIT.
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

  # *optionally* throttle the master from forking too quickly by sleeping
  sleep 1
end
