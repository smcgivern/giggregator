require 'lib/model'

require 'rdiscount'

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

  def updated; band.gigs_updated; end
  def time_period; TIME_PERIODS.detect {|t| t.criteria[time]}; end

  def time_formatted
    time.strftime(TIME_FORMAT).gsub(/( |\A)0(\d\D)/, '\1\2')
  end

  def title_by_time_period
    format_fields([band.title, location, time_formatted])
  end

  def format_fields(fields)
    RDiscount.new(fields.join(' -- '), :smart).to_html
  end
end
