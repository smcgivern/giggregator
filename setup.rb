require 'fileutils'
require 'logger'
require 'timeout'
require 'vendor/rubypants'

require 'haml'
require 'sass'
require 'sequel'
require 'sinatra'

def acquire(dir); Dir["#{dir}/*.rb"].each {|f| require f}; end

acquire 'lib'

FEED_DIR = 'tmp/feed'
LOG_DIR = 'log'
LOG_SQLITE = 'sqlite.log'
DB_SQLITE = 'tmp/giggregator.db'
ROOT_URL = 'http://giggregator.sean.mcgivern.me.uk'

CONTENT_TYPES = {
  :atom => 'application/atom+xml',
  :html => 'text/html',
  :css => 'text/css',
  :js => 'application/javascript',
}

TIME_PERIODS = [
  TimePeriod.new('Next day', lambda {|t| t <= Days(1)}),
  TimePeriod.new('Next week', lambda {|t| t <= Days(7)}),
  TimePeriod.new('Next month', lambda {|t| t <= Days(30)}),
  TimePeriod.new('Later', lambda {|t| true}),
]

DB = Sequel.sqlite(DB_SQLITE)

[FEED_DIR, LOG_DIR].each do |dir|
  FileUtils.mkdir(dir) unless File.exist?(dir)
end

DB.logger = Logger.new(File.join(LOG_DIR, LOG_SQLITE))

acquire 'model'
