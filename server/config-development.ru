require 'rack/unreloader'
require 'rubygems'
require 'bundler'
require 'yaml'
Bundler.require
require '../lib/humps'
require File.join(File.dirname(__FILE__), 'db', 'db_connector.rb')

Unreloader = Rack::Unreloader.new { HumpServer }
Unreloader.require './hump_server.rb'
run Unreloader
