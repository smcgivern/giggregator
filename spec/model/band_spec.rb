require 'spec/setup'

require 'model/band'
require 'model/bands_gig_list'
require 'model/gig'
require 'model/gig_list'

def type(t); lambda {|x| t === x}; end

class Band < Sequel::Model
  def self.using_replacement_method(method_name)
    alias_method(:"old_#{method_name}", method_name)
    alias_method(method_name, :"replacement_#{method_name}")
    yield
    alias_method(method_name, :"old_#{method_name}")
  end

  def self.using_replacement_template(key)
    templates = {
      :band => 'spec/fixture/{myspace_name}.html',
      :gig_list => 'spec/fixture/{friend_id}_gigs_{p}.html',
    }

    original = TEMPLATES[key]
    TEMPLATES[key] = Addressable::Template.new(templates[key])
    yield
    TEMPLATES[key] = original
  end

  def replacement_load_band_info!; 'Loaded band info'; end
  def replacement_load_gigs!
    add_gig(Gig.create(:title => 'Test gig', :time => Time.now + 60))
    update(:gigs_updated => Time.now)
    gigs
  end
end

describe 'Band.from_myspace' do
  it 'should extract the MySpace name from the URI' do
    Band.create(:myspace_name => 'from_uri',
                :band_info_updated => Time.now)

    Band.from_myspace('http://www.myspace.com/from_uri').myspace_name.
      should.equal 'from_uri'

    Band.from_myspace('http://myspace.com/from_uri').myspace_name.
      should.equal 'from_uri'
  end

  it 'should also work with just the MySpace name' do
    Band.create(:myspace_name => 'from_name',
                :band_info_updated => Time.now)

    Band.from_myspace('from_name').myspace_name.
      should.equal 'from_name'
  end

  it 'should load the band info and return the band' do
    Band.using_replacement_method(:load_band_info!) do
      band = Band.from_myspace('eighthdaydescent')

      band.myspace_name.should.equal 'eighthdaydescent'
      Band[:myspace_name => 'eighthdaydescent'].should.not.equal nil
    end
  end

  it 'should return the band if one already exists' do
    Band.using_replacement_method(:load_band_info!) do
      original = Band.from_myspace('dlmethod')
      copy = Band.from_myspace('dlmethod')

      original.id.should.equal copy.id
    end
  end

  it 'should fail and not update DB if the page is not a band page' do
    Band.using_replacement_template(:band) do
      Band.from_myspace('nokogiri')
      Band[:myspace_name => 'nokogiri'].should.equal nil
    end
  end
end

describe 'Band#expired?' do
  it 'should return true if there is no _updated value' do
    Band.new.expired?(:band_info).should.be.true
    Band.new.expired?(:gigs).should.be.true
  end

  it 'should return true if the _updated value is past its TTL' do
    eight_days_ago = Time.now - 691_200
    band = Band.create(:band_info_updated => eight_days_ago,
                       :gigs_updated => eight_days_ago)

    band.expired?(:band_info).should.be.false
    band.expired?(:gigs).should.be.true
  end
end

describe 'Band#uri' do
  it 'should convert a string to an Addressable URI' do
    Band.new.uri('').
      should.be.a type(Addressable::URI)
  end
end

describe 'Band#parse' do
  before {@doc = Band.new.parse('spec/fixture/nokogiri.html')}

  it 'should use Nokogiri to parse the filename given' do
    @doc.should.be.a type(Nokogiri::HTML::Document)
  end

  it 'should use UTF-8 encoding' do
    @doc.at('title').inner_text.should.equal "The D\303\270"
  end
end

describe 'Band#load_band_info?' do
  it 'should run load_band_info! if the band info is expired' do
    Band.using_replacement_method(:load_band_info!) do
      Band.new.load_band_info?.should.equal 'Loaded band info'

      Band.create(:band_info_updated => Time.now).load_band_info?.
        should.equal nil
    end
  end
end

describe 'Band#load_gigs?' do
  Band.using_replacement_method(:load_gigs!) do
    it 'should run load_gigs! if the gigs are expired' do
      band = Band.create
      band.load_gigs?
      band.expired?(:gigs).should.be.false
      band.load_gigs?.should.equal nil

      Band.create(:gigs_updated => Time.now).load_gigs?.
        should.equal nil
    end

    it 'should return the gigs, not the band' do
      Band.create.load_gigs?.first.title.should.equal 'Test Gig'
    end
  end
end

describe 'Band#gigs' do
  it 'should load gigs if required, and then return the gigs' do
    Band.using_replacement_method(:load_gigs!) do
      band = Band.create
      band.gigs.first.title.should.equal 'Test Gig'
      band.gigs.first.title.should.equal 'Test Gig'
    end
  end
end

describe 'Band#gig_list' do
  Band.using_replacement_method(:load_gigs!) do
    before do
      @band = Band.find_or_create(:myspace_name => 'test')
      @band.load_gigs?
    end

    it "should return a gig list with only this band's gigs" do
      @band.gig_list.should.be.a type(GigList)
      @band.gig_list.gig_list.first.band.should.equal @band
    end

    it 'should give the gig list the title __myspace_name' do
      @band.gig_list.title.should.equal '__test'
    end
  end
end

describe 'Band#page_uri' do
  it "should be the URI of the band's MySpace page" do
    Band.new(:myspace_name => 'anebrun').page_uri.
      should.equal Band.new.uri('http://www.myspace.com/anebrun')
  end
end

describe 'Band#gig_page_uri' do
  before do
    @band = Band.new(:friend_id => '181410567')
    @gig_page_uri = 'http://events.myspace.com/181410567/Events/1'
  end

  it "should be the the URI of the band's gig page" do
    @band.gig_page_uri.should.equal Band.new.uri(@gig_page_uri)
  end
end

describe 'Band#load_band_info!' do
  Band.using_replacement_template(:band) do
    it 'should extract the title and friend ID, returning the band' do
      band = Band.
        find_or_create(:myspace_name => 'thiswilldestroyyou').
        load_band_info!

      band.title.should.equal 'This Will Destroy You'
      band.friend_id.should.equal 7333792
      band.band_info_updated.should.be {|t| t >= Time.now + 60}
    end

    it 'should raise NotABandError when there is no gig link' do
      should.raise(NotABandError) do
        Band.create(:myspace_name => 'nokogiri').load_band_info!
      end
    end

    it 'should not error if there is already a friend ID' do
      band = Band.
        find_or_create(:myspace_name => 'thiswilldestroyyou').
        load_band_info!

      band.myspace_name = 'thiswilldeployyou'
      band.load_band_info!

      band.friend_id.should.equal 7333792
      band.band_info_updated.should.be {|t| t >= Time.now + 60}
    end
  end
end

describe 'Band#load_gigs!' do
  Band.using_replacement_template(:gig_list) do
    before do
      @band = Band.find_or_create(:friend_id => 6114901)
      @band.load_gigs?

      def strip_gig_times(gigs)
        gigs.map {|g| g.to_yaml.gsub(/\n  :updated: .*?\n/, "\n")}
      end
    end

    it 'should follow multiple pages, if they exist' do
      band = Band.find_or_create(:friend_id => 65642225)
      band.load_gigs!
      band.gigs.length.should.equal 13
    end

    it 'should extract the time, title, and location' do
      @band.gigs.first.title.should.equal 'Asobi Seksu'
      @band.gigs.first.location.should.equal 'Bkln Yard'
      @band.gigs.first.time.strftime('20XX-%m-%dT%T%z').
        should.equal '20XX-07-16T16:00:00+0000'
    end

    it 'should treat times in the past as happening next year' do
      band = Band.find_or_create(:friend_id => 111111111)
      band.load_gigs!
      band.gigs.each {|g| g.time.should.satisfy {|t| t >= Time.now}}
    end

    it "should parse the special dates 'today' and 'tomorrow'" do
      band = Band.find_or_create(:friend_id => 61149013)
      band.load_gigs!
      band.gigs.each {|g| g.time.should.satisfy {|t| t >= Time.now}}
      band.gigs.length.should.equal Time.now.utc.hour >= 20 ? 1 : 2
    end

    it 'should extract the address as a comma-separated list' do
      @band.gigs.first.address.should.equal 'Brooklyn, New York'
    end

    it "should return the band's gigs" do
      @band.load_gigs!.should.equal @band.gigs
    end

    it 'should use an alternative time format if required' do
      band = Band.find_or_create(:friend_id => 60520888)
      band.load_gigs!

      band.gigs.length.should.equal 3
      band.gigs.first.time.strftime('%T').should.equal '20:00:00'
      band.gigs.last.time.strftime('20XX-%m-%dT%T%z').
        should.equal '20XX-10-16T20:00:00+0000'
    end

    it 'should not duplicate gigs' do
      strip_gig_times(@band.gigs).
        should.equal strip_gig_times(@band.load_gigs!)
    end

    it 'should overwrite duplicate gigs with the new title' do
      @band.friend_id = 61149011
      gig_updated = @band.gigs.first.updated

      @band.load_gigs!

      @band.gigs.first.title.should.satisfy {|t| t =~ /\ADuplicate/}
      @band.gigs.first.updated.should.satisfy {|t| t > gig_updated}
    end

    it 'should remove old gigs' do
      gig = Gig.create(:time => Time.now - 6000, :updated => Time.now)

      @band.add_gig(gig)
      @band.gigs.should.satisfy {|g| g.include?(gig)}

      @band.load_gigs!
      @band.gigs.should.satisfy {|g| !g.include?(gig)}
    end

    it "should update the gig's updated field if it's a new gig" do
      gig_updated = @band.gigs.first.updated
      @band.friend_id = 61149012

      @band.load_gigs!

      @band.gigs.first.updated.
        should.satisfy {|t| t - 60 <= gig_updated}

      @band.gigs.sort_by {|g| g.updated}.last.
        should.satisfy {|g| g.updated > gig_updated}
    end
  end
end
