require 'fileutils'
require 'logger'
require 'sequel'

LOG_DIR = File.join(File.dirname(__FILE__), 'log')
LOG_SQLITE = 'sqlite.log'

DB = Sequel.sqlite

require 'model/band'
require 'model/gig'

FileUtils.mkdir(LOG_DIR) unless File.exist?(LOG_DIR)
DB.logger = Logger.new(File.join(LOG_DIR, LOG_SQLITE))
