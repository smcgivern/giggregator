require 'sequel'

Sequel::Model.plugin(:schema)

class Sequel::Model
  def self.create_schema(&b); set_schema(&b); create_table?; end

  def self.capitalize(*methods)
    methods.each do |method|
      define_method method do
        if super
          super.split.
            map {|w| w.capitalize}.join(' ').
            gsub(/(\A\W|\W\W)[a-z]/u) {|l| l.upcase}
        end
      end
    end
  end
end
