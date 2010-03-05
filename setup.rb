require 'fileutils'
require 'logger'
require 'timeout'
require 'vendor/rubypants'

require 'haml'
require 'openid'
require 'openid/store/filesystem'
require 'sass'
require 'sequel'
require 'sinatra'

def acquire(dir); Dir["#{dir}/*.rb"].each {|f| require f}; end

acquire 'lib'

GOOGLE_MAPS_API_KEY = 'ABQIAAAAIMsc0fFg7uQ53CccTk6oEhR-lgg7DzJwhYtAcnHQYGQig9oPuxSkU_WH7PZwwvsCrZCJTmjWtCi4gg'
FEED_DIR = 'tmp/feed'
LOG_DIR = 'log'
LOG_SINATRA = 'sinatra.log'
LOG_SQLITE = 'sqlite.log'
DB_SQLITE = 'tmp/giggregator.db'
OPENID_STORE = 'tmp/openid'

CONTENT_TYPES = {
  :atom => 'application/atom+xml',
  :html => 'text/html',
  :css => 'text/css',
  :js => 'text/javascript', # For Internet Explorer
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
SINATRA_LOG = File.new(File.join(LOG_DIR, LOG_SINATRA), 'a')

$stdout.reopen(SINATRA_LOG)
$stderr.reopen(SINATRA_LOG)

acquire 'model'
