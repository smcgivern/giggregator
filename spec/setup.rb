require 'bundler/setup'
require 'bacon'
require 'sequel'

Sequel.default_timezone = :utc
DB = Sequel.sqlite
