require 'lib/model'

class Gig < Sequel::Model
  many_to_one :band

  create_schema do
    primary_key(:id)
    foreign_key(:band_id)
    DateTime(:time)
    String(:title)
    String(:location)
    String(:address)
  end
end
