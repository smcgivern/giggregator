require 'fileutils'
require 'logger'
require 'timeout'

require 'feed_tools'
require 'haml'
require 'sequel'
require 'sinatra'
require 'uuidtools'

def acquire(dir); Dir["#{dir}/*.rb"].each {|f| require f}; end

acquire 'lib'

FEED_DIR = 'tmp/feed'
LOG_DIR = 'log'
LOG_SQLITE = 'sqlite.log'
DB_SQLITE = 'giggregator.db'
ROOT_URL = 'http://giggregator.sean.mcgivern.me.uk'

# Monkey patch to let FeedTools work with UUIDTools
UUID_URL_NAMESPACE = UUIDTools::UUID_URL_NAMESPACE
UUID = UUIDTools::UUID

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

DB = Sequel.sqlite()

[FEED_DIR, LOG_DIR].each do |dir|
  FileUtils.mkdir(dir) unless File.exist?(dir)
end

DB.logger = Logger.new(File.join(LOG_DIR, LOG_SQLITE))

acquire 'model'
