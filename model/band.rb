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

  BASE_URL = 'http://www.myspace.com'

  TEMPLATES = {
    :band => "#{BASE_URL}/{myspace_name}",
    :gig_list => "#{BASE_URL}/{myspace_name}/shows",
    :gig_page => "#{BASE_URL}/events/View/{event_id}/{title}",
  }

  SELECTORS = {
    :band_name => 'section.sitesHeader a.userLink',
    :friend_id => 'a.gapBlockUser',
    :gig_page => 'li.last a',
    :gig_info => 'li.event',
    :gig_info_title => 'div.details h4 a',
    :gig_info_address => 'div.details p',
    :gig_info_month => 'div.entryDate span.month',
    :gig_info_day => 'div.entryDate span.day',
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
    rescue NotABandError, Timeout::Error, OpenURI::HTTPError
      band.destroy if band
    end
  end

  def expired?(type)
    return true unless (value = values[:"#{type}_updated"])
    Time.now >= value + TTLS[type]
  end

  def uri(s); Addressable::URI.parse(s); end
  def parse(s); Nokogiri::HTML(open(s).read); end
  def element(p, s); p.at(SELECTORS[s]); end

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

  def gig_page_uri
    TEMPLATES[:gig_list].expand('myspace_name' => myspace_name)
  end

  def load_band_info!
    band_page = parse(page_uri)
    gig_link = element(band_page, :gig_page)
    params = {:band_info_updated => Time.now}

    if gig_link
      gig_link = TEMPLATES[:gig_list].extract(uri(gig_link['href']))

      params[:title] = element(band_page, :band_name).inner_text

      params[:friend_id] =
        element(band_page, :friend_id)['data-friendid']
    else
      raise NotABandError unless friend_id
    end

    update(params)
    save
  end

  def load_gigs!
    def to_time(d, &b); Time.parse(d.new_offset(0).to_s, &b); end

    page = parse(gig_page_uri)
    page.search(SELECTORS[:gig_info]).each do |gig_info|
      title, address, month, day =
        [:title, :address, :month, :day].map do |key|
          element(gig_info, "gig_info_#{key}".to_sym).inner_text.strip
        end

      event_id = BASE_URL + element(gig_info, :gig_info_title)['href']
      event_id = TEMPLATES[:gig_page].extract(event_id)['event_id']

      location = title
      now = Time.now
      time = DateTime.strptime("#{day} #{month} #{now.year} 23:59:59",
                               '%d %b %Y %H:%M:%S')

      time = to_time(time) {|y| y + (to_time(time) < now ? 1 : 0)}

      gig = Gig.find_or_create(:time => time, :band_id => id)
      cols = {:title => title, :location => location,
        :address => address, :event_id => event_id}

      cols.each do |col, val|
        gig.updated = Time.now if gig[col] != val

        gig[col] = val
      end

      gig.save

      add_gig(gig) unless gigs_dataset.all.include?(gig)
    end

    gigs_dataset.filter {|g| g.time < Time.now}.delete

    update(:gigs_updated => Time.now)
    save
    gigs
  end
end
