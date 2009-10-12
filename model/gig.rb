require 'lib/model'

class Gig < Sequel::Model
  many_to_one :band

  TIME_FORMAT = '%d %b %Y at %I:%M %p'

  create_schema do
    primary_key(:id)
    foreign_key(:band_id)
    DateTime(:time)
    String(:title)
    String(:location)
    String(:address)
  end

  def time_period; TIME_PERIODS.detect {|t| t.criteria[time]}; end

  def time_formatted; time.strftime(TIME_FORMAT); end
end
