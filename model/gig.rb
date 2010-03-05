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
    DateTime(:updated)
  end

  capitalize :title, :location, :address

  def time; values[:time].utc; end

  def time_period(col=:time)
    TIME_PERIODS.detect {|t| t.criteria[send(col)]}
  end

  def format_time(fmt); strip_leading_zeroes(time.strftime(fmt)); end
  def strip_leading_zeroes(s); s.gsub(/( |\A)0(\d)/, '\1\2'); end

  def time_formatted; format_time(TIME_FORMAT); end
  def date_formatted; format_time(DATE_FORMAT); end

  def span_elements(elements)
    elements.map do |element|
      "<span class=\"#{element[:title]}\">#{element[:text]}</span>"
    end.join(' --- ')
  end

  def title_by_time_period
    span_elements([
                   {:title => 'band', :text => band.title},
                   {:title => 'address', :text => address},
                   {:title => 'time', :text => time_formatted},
                  ])
  end

  def title_by_band
    span_elements([
                   {:title => 'address', :text => address},
                   {:title => 'time', :text => time_formatted},
                  ])
  end
end
