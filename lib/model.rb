require 'sequel'

Sequel::Model.plugin(:schema)

class Sequel::Model
  def self.create_schema(exclude_timestamp=nil, &block)
    set_schema(&block)

    unless exclude_timestamp
      schema.timestamp(:updated)

      def before_save; set(:updated => Time.now); end
    end

    create_table?
  end
end
