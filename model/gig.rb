require 'lib/model'

class Gig < Sequel::Model
  many_to_one :band

  TIME_FORMAT = '%d %b %Y at %I:%M %p'
  DATE_FORMAT = '%d %b %Y'

  create_schema do
    primary_key(:id)
    foreign_key(:band_id)
    DateTime(:time)
    String(:title)
    String(:location)
    String(:address)
  end

  def time; values[:time]; end
  def updated; band.gigs_updated; end
  def time_period; TIME_PERIODS.detect {|t| t.criteria[time]}; end

  def strip_leading_zeroes(s); s.gsub(/( |\A)0(\d\D)/, '\1\2'); end
  def format_fields(fields); fields.join(' -- '); end
  def format_time(fmt); strip_leading_zeroes(time.strftime(fmt)); end

  def time_formatted; format_time(TIME_FORMAT); end
  def date_formatted; format_time(DATE_FORMAT); end

  def title_by_time_period
    format_fields([band.title, location, time_formatted])
  end
end
