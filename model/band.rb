require 'lib/model'

require 'date'
require 'open-uri'
require 'timeout'

require 'addressable/template'
require 'addressable/uri'
require 'nokogiri'

class NotABandError < Exception; end

class Band < Sequel::Model
  one_to_many :gigs
  many_to_many :gig_lists

  create_schema do
    primary_key(:id)
    String(:myspace_name, :unique => true)
    Integer(:friend_id)
    String(:title)
    DateTime(:band_info_updated)
    DateTime(:gigs_updated)
  end

  capitalize :title

  TIME_FORMAT = '%m-%d-%Y %H:%M'

  TEMPLATES = {
    :band => 'http://www.myspace.com/{myspace_name}',
    :gig_list => 'http://events.myspace.com/{friend_id}/Events/{p}',
    :gig_page => 'http://events.myspace.com/Event/{event_id}/{title}',
  }

  SELECTORS = {
    :band_name => 'meta[property="myspace:profileType"]',
    :gig_page => '#profile_bandschedule a.whitelink',
    :gig_list_pages => 'div.paginateCenter a',
    :gig_info => 'table[width="615"] form',
    :form_input => 'input[name="calEvt%s"]',
  }

  TTLS = {
    :gigs => 7,
    :band_info => 30,
  }

  # Convert templates from string to URI template
  TEMPLATES.each {|k, v| TEMPLATES[k] = Addressable::Template.new(v)}

  # TTLs are given in days
  TTLS.each {|k, v| TTLS[k] = TTLS[k] * 86_400}

  def self.from_myspace(myspace_uri)
    params = {:myspace_name => myspace_uri.split('/').last}

    begin
      band = Band.find_or_create(params)
      band.load_band_info?
      band
    rescue NotABandError, Timeout::Error
      band.destroy if band
    end
  end

  def expired?(type)
    return true unless (value = values[:"#{type}_updated"])
    Time.now >= value + TTLS[type]
  end

  def uri(s); Addressable::URI.parse(s); end
  def parse(s); Nokogiri::HTML(open(s).read); end

  def load_band_info?; load_band_info! if expired?(:band_info); end
  def load_gigs?; load_gigs! if expired?(:gigs); end
  def gigs; load_gigs?; gigs_dataset.all; end

  def gig_list
    return @gig_list if @gig_list

    @gig_list = GigList.find_or_create(:title => "__#{myspace_name}",
                                       :system => true)

    @gig_list.add_band(self) unless @gig_list.bands == [self]
    @gig_list
  end

  def page_uri
    TEMPLATES[:band].expand('myspace_name' => myspace_name)
  end

  def gig_page_uri(p=1)
    TEMPLATES[:gig_list].expand('friend_id' => friend_id, 'p' => p)
  end

  def load_band_info!
    band_page = parse(page_uri)
    gig_link = band_page.at(SELECTORS[:gig_page])
    params = {:band_info_updated => Time.now}

    if gig_link
      gig_link = TEMPLATES[:gig_list].extract(uri(gig_link['href']))

      params[:title] = band_page.at(SELECTORS[:band_name])['about']
      params[:friend_id] = gig_link['friend_id']
    else
      raise NotABandError unless friend_id
    end

    update(params)
    save
  end

  def load_gigs!
    pages = [parse(gig_page_uri)]
    page_div = pages.first.search(SELECTORS[:gig_list_pages])
    page_count = page_div.first ? page_div.last.inner_text.to_i : 1

    (2..page_count).each {|p| pages << parse(gig_page_uri(p))}

    pages.each do |page|

    end

    update(:gigs_updated => Time.now)
    save
    gigs
  end
end
