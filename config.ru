require 'bundler/setup'
require 'rack'
require './setup'
require './giggregator'

run Sinatra::Application
