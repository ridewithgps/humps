require 'pg'

class DbConnector
  class ConnectionFailedError < RuntimeError; end

  def initialize(args)
    @servers = args
    @connect_timeout = 2
    @global_timeout = (@servers.length+1) * @connect_timeout
  end

  def conn
    @conn ||= attempt_connection
  end

  def reset_connection
    @conn.close if @conn && @conn.status == PG::Constants::CONNECTION_OK
    @conn = attempt_connection
  end

  def attempt_connection
    if s = next_server
      begin
        #puts "attempting to connect to #{s}"
        return PG.connect(
          host: s['host'],
          port: s['port'],
          user: s['user'],
          dbname: s['name'],
          connect_timeout: @connect_timeout
        )
      rescue
        #puts "exception time: #{s}"
        s[:last_failed] = Time.now.to_i
        attempt_connection
      end
    else
      raise ConnectionFailedError.new("No available server to connect to")
    end
  end

  def next_server
    @servers.each do |s|
      if s[:last_failed].nil? ||
        (Time.now.to_i - s[:last_failed]) > @global_timeout
        #puts "returning server #{s}"
        return s
      end
    end
    nil
  end
end
