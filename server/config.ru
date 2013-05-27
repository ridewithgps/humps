require 'rubygems'
require 'bundler'
Bundler.require
require '../lib/humps.rb'
require File.join(File.dirname(__FILE__), 'hump_server.rb')

run HumpServer
