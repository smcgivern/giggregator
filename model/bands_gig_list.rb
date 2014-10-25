require './lib/model'

class BandsGigList < Sequel::Model
  create_schema do
    primary_key(:id)
    foreign_key(:band_id)
    foreign_key(:gig_list_id)
  end
end
