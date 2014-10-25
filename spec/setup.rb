require 'bundler/setup'
require 'bacon'
require 'sequel'

Encoding.default_external = Encoding::UTF_8

Sequel.default_timezone = :utc
DB = Sequel.sqlite
