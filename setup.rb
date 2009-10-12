require 'fileutils'
require 'logger'
require 'sequel'

def acquire(dir); Dir["#{dir}/*.rb"].each {|f| require f}; end

acquire 'lib'

ROOT_DIR = 'giggregator'
LOG_DIR = 'log'
LOG_SQLITE = 'sqlite.log'
DB_SQLITE = 'giggregator.db'

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

LOG_DIR_PATH = File.join(File.dirname(__FILE__), LOG_DIR)
FileUtils.mkdir(LOG_DIR_PATH) unless File.exist?(LOG_DIR_PATH)
DB.logger = Logger.new(File.join(LOG_DIR_PATH, LOG_SQLITE))

acquire 'model'
