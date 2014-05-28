require 'rubygems'
require 'bundler'
require 'yaml'
Bundler.require
require '../lib/humps.rb'
require File.join(File.dirname(__FILE__), 'hump_server.rb')

run HumpServer
