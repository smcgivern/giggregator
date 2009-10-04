require 'date'
require 'open-uri'

require 'addressable/template'
require 'addressable/uri'
require 'nokogiri'

require 'database'

class Band < Sequel::Model(:band)
  TIME_FORMAT = '%m-%d-%Y %H:%M'

  TEMPLATES = {
    :band => 'http://www.myspace.com/{myspace_name}',
    :gig => 'http://collect.myspace.com/index.cfm?fuseaction=bandprofile.listAllShows&friendid={friend_id}&n={name}',
  }

  SELECTORS = {
    :band_name => 'meta[property="myspace:profileType"]',
    :gig_page => '#profile_bandschedule a.whitelink',
    :gig_info => 'table[width="615"] form',
    :form_input => 'input[name="calEvt%s"]',
  }

  TEMPLATES.each {|k, v| TEMPLATES[k] = Addressable::Template.new(v)}

  def initialize(val)
    super(:myspace_name => val)
    load_band_info
  end

  def uri(s); Addressable::URI.parse(s); end
  def parse(s); Nokogiri::HTML(open(s)); end

  def page_uri
    TEMPLATES[:band].expand(:myspace_name => myspace_name)
  end

  def gig_page_uri
    TEMPLATES[:gig].expand(:friend_id => friend_id, :name => name)
  end

  def load_band_info
    band_page = parse(page_uri)
    gig_link = uri(band_page.at(SELECTORS[:gig_page])['href'])

    update(
           :name => band_page.at(SELECTORS[:band_name])['about'],
           :friend_id => TEMPLATES[:gig].extract(gig_link)[:friend_id]
           )
  end

  def load_gigs
    def value(k, e); e.at(SELECTORS[:form_input] % k)['value']; end

    gigs = []

    parse(gig_page_uri).search(SELECTORS[:gig_info]).each do |gig|
      time = DateTime.strptime(value('DateTime', gig), TIME_FORMAT)
      location = value('Location', gig)
      title = value('Title', gig)

      address = ['City', 'State', 'Zip'].
        map {|k| value(k, gig)}.reject {|x| x.empty?}.
        join(', ')

      gigs << {
        :time => time, :title => title, :location => location,
        :address => address,
      }
    end
  end
end

Band.unrestrict_primary_key
