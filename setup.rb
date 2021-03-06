require 'fileutils'
require 'logger'
require 'timeout'
require 'rubypants'

require 'haml'
require 'openid'
require 'openid/store/filesystem'
require 'sass'
require 'sequel'
require 'sinatra'

Encoding.default_external = Encoding::UTF_8

def acquire(dir); Dir["#{dir}/*.rb"].each {|f| require "./#{f}"}; end

acquire 'lib'

GOOGLE_MAPS_API_KEY = File.open('.gmaps').read.strip
ROOT = (File.exist?('.root') ?
        File.open('.root').read.strip : nil)

GOOGLE_MAPS_PREFIX = 'http://maps.google.com/maps?file=api&v=2.x&key='
GOOGLE_MAPS_SCRIPT = GOOGLE_MAPS_PREFIX + GOOGLE_MAPS_API_KEY
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

TIME_PERIODS =
  [
   TimePeriod.new('Next day', lambda {|t| Between(t, 0, 1)}),
   TimePeriod.new('Next week', lambda {|t| Between(t, 0, 7)}),
   TimePeriod.new('Next month', lambda {|t| Between(t, 0, 30)}),
   TimePeriod.new('Later', lambda {|t| Between(t, 0)}),

   # Reversed, for freshness view
   TimePeriod.new('Last day', lambda {|t| Between(t, -1, 0)}),
   TimePeriod.new('Last week', lambda {|t| Between(t, -7, 0)}),
   TimePeriod.new('Last month', lambda {|t| Between(t, -30, 0)}),
   TimePeriod.new('Earlier', lambda {|t| Between(t, nil, 0)}),
  ]

Sequel.default_timezone = :utc
DB = Sequel.sqlite(DB_SQLITE)

[FEED_DIR, LOG_DIR].each do |dir|
  FileUtils.mkdir(dir) unless File.exist?(dir)
end

DB.logger = Logger.new(File.join(LOG_DIR, LOG_SQLITE))
SINATRA_LOG = File.new(File.join(LOG_DIR, LOG_SINATRA), 'a')

configure do
  SINATRA_LOG.sync = true

  use Rack::CommonLogger, SINATRA_LOG
end

acquire 'model'
