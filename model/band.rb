require 'lib/model'

require 'date'
require 'open-uri'
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

  TTLS = {
    :gigs => 7,
    :band_info => 30,
  }

  # Convert templates from string to URI template
  TEMPLATES.each {|k, v| TEMPLATES[k] = Addressable::Template.new(v)}

  # TTLs are given in days
  TTLS.each {|k, v| TTLS[k] = TTLS[k] * 86_400}

  def self.from_myspace(myspace_name)
    params = {:myspace_name => myspace_name.split('/').last}

    band = Band.find_or_create(params)
    band.load_band_info?
    band
  end

  def expired?(type)
    !((value = values["#{type}_updated".to_sym]) &&
      Time.now <= value + TTLS[type])
  end

  def uri(s); Addressable::URI.parse(s); end
  def parse(s); Nokogiri::HTML(open(s).read); end

  def load_band_info?; load_band_info! if expired?(:band_info); end
  def load_gigs?; load_gigs! if expired?(:gigs); end
  def gigs; load_gigs?; super; end

  def gig_list
    return @gig_list if @gig_list

    @gig_list = GigList.find_or_create(:title => "__#{myspace_name}",
                                       :system => true)

    @gig_list.remove_all_bands
    @gig_list.add_band(self)
    @gig_list
  end

  def page_uri
    TEMPLATES[:band].expand('myspace_name' => myspace_name)
  end

  def gig_page_uri
    params = {'friend_id' => friend_id.to_s, 'name' => title}

    TEMPLATES[:gig].expand(params)
  end

  def load_band_info!
    band_page = parse(page_uri)
    gig_link = band_page.at(SELECTORS[:gig_page])

    raise NotABandError unless gig_link

    gig_link = uri(gig_link['href'])
    params = {
      :title => band_page.at(SELECTORS[:band_name])['about'],
      :friend_id => TEMPLATES[:gig].extract(gig_link)['friend_id'],
      :band_info_updated => Time.now,
    }

    update(params)
    save
  end

  def load_gigs!
    def value(k, e); e.at(SELECTORS[:form_input] % k)['value']; end

    parse(gig_page_uri).search(SELECTORS[:gig_info]).each do |gig|
      time = DateTime.strptime(value('DateTime', gig), TIME_FORMAT)
      location = value('Location', gig)
      title = value('Title', gig)

      address = ['City', 'State', 'Zip'].
        map {|k| value(k, gig)}.reject {|x| x.empty?}.
        join(', ')

      params = {
        :time => time, :title => title, :location => location,
        :address => address,
      }

      add_gig(Gig.find_or_create(params))
    end

    update(:gigs_updated => Time.now)
    gigs
  end
end
