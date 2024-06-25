require 'rubygems'
require 'bundler'
require 'yaml'
Bundler.require
require '../lib/humps'
require File.join(File.dirname(__FILE__), 'db', 'db_connector.rb')
require File.join(File.dirname(__FILE__), 'hump_server.rb')

run HumpServer
