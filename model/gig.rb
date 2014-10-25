require './lib/model'
require './model/band'

class Gig < Sequel::Model
  many_to_one :band

  TIME_FORMAT = '%d %b %Y'
  DATE_FORMAT = '%d %b %Y'

  create_schema do
    primary_key(:id)
    foreign_key(:band_id)
    DateTime(:time)
    String(:title)
    String(:location)
    String(:address)
    Integer(:event_id)
    DateTime(:updated)
  end

  capitalize :title, :location, :address

  def time; values[:time].utc; end

  def event_id
    if (val = values[:event_id])
      BigDecimal === val ? val.to_s('F').split('.').first : val.to_s
    end
  end

  def time_period(col=:time)
    TIME_PERIODS.detect {|t| t.criteria[send(col)]}
  end

  def format_time(fmt); strip_leading_zeroes(time.strftime(fmt)); end
  def strip_leading_zeroes(s); s.gsub(/( |\A)0(\d)/, '\1\2'); end

  def time_formatted; format_time(TIME_FORMAT); end
  def date_formatted; format_time(DATE_FORMAT); end

  def span_elements(elements)
    elements.map do |element|
      unless element[:text].empty?
        "<span class=\"#{element[:title]}\">#{element[:text]}</span>"
      end
    end.compact.join(' --- ')
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

  def uri
    if event_id
      Band::TEMPLATES[:gig_page].expand('event_id' => event_id,
                                        'title' => title)
    end
  end
end
