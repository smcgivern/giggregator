require 'fileutils'
require 'logger'
require 'sequel'

LOG_DIR = File.join(File.dirname(__FILE__), 'log')
LOG_SQLITE = 'sqlite.log'

DB = Sequel.sqlite

FileUtils.mkdir(LOG_DIR) unless File.exist?(LOG_DIR)
DB.logger = Logger.new(File.join(LOG_DIR, LOG_SQLITE))

def create_unless_exists(db, table, &block)
  db.create_table(table, &block) unless db.table_exists?(table)
end

create_unless_exists(DB, :band) do
  primary_key(:myspace_name, :string, :auto_increment => false)
  Integer(:friend_id)
  String(:name)
end

create_unless_exists(DB, :gig) do
  primary_key([:myspace_name, :time, :title])
  foreign_key(:myspace_name, :band)
  DateTime(:time)
  String(:title)
  String(:location)
  String(:address)
  DateTime(:updated)
end
