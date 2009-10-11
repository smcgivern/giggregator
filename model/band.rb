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

  TEMPLATES.each {|k, v| TEMPLATES[k] = Addressable::Template.new(v)}

  def self.from_myspace(myspace_name)
    params = {:myspace_name => myspace_name.split('/').last}

    Band.find_or_create(params).load_band_info?
  end

  def uri(s); Addressable::URI.parse(s); end
  def parse(s); Nokogiri::HTML(open(s).read); end

  def load_band_info?; load_band_info! unless title; self.save; end
  def load_gigs?
    load_gigs! if gigs_dataset.empty? and not @gigs_loaded
  end

  def gigs; load_gigs?; super; end
  def gig_list; GigList.new(self); end

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
    }

    update(params)
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

    @gigs_loaded = true

    gigs
  end
end
