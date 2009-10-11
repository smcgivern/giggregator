require 'fileutils'
require 'logger'
require 'sequel'

ROOT_DIR = ''
LOG_DIR = 'log'
LOG_SQLITE = 'sqlite.log'
DB_SQLITE = 'giggregator.db'

CONTENT_TYPES = {
  :atom => 'application/atom+xml',
  :html => 'text/html',
  :css => 'text/css',
  :js => 'application/javascript',
}

DB = Sequel.sqlite()

LOG_DIR_PATH = File.join(File.dirname(__FILE__), LOG_DIR)
FileUtils.mkdir(LOG_DIR_PATH) unless File.exist?(LOG_DIR_PATH)
DB.logger = Logger.new(File.join(LOG_DIR_PATH, LOG_SQLITE))
Dir['model/*.rb'].each {|m| require m}
