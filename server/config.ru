require 'rubygems'
require 'sinatra'
require 'json'
require File.join(File.dirname(__FILE__), 'server.rb')

root_dir = File.dirname(__FILE__)

set :environment, :production
set :root, root_dir
set :app_file, File.join(root_dir, 'server.rb')
disable :run

FileUtils.mkdir_p 'log' unless File.exists?('log')
#stdoutlog = File.new("log/sinatra.stdout.log", "a")
#stderrlog = File.new("log/sinatra.stderr.log", "a")
#$stdout.reopen(stdoutlog)
#$stderr.reopen(stderrlog)

run Sinatra::Application
