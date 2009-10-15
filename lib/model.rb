require 'sequel'

Sequel::Model.plugin(:schema)

class Sequel::Model
  def self.create_schema(&b); set_schema(&b); create_table?; end
end
