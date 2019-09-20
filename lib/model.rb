require 'sequel'

Sequel::Model.plugin(:schema)

class Sequel::Model
  def self.create_schema(&b); set_schema(&b); create_table?; end

  def self.capitalize(*methods)
    methods.each do |method|
      define_method method do |*args|
        if (sup = super(*args))
          sup.split.
            map {|w| w.capitalize.force_encoding(Encoding::UTF_8)}.join(' ').
            gsub(/(\A\W|\W\W)[a-z]/u) {|l| l.upcase}
        end
      end
    end
  end
end
