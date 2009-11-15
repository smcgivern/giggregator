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

  def replacement_page_uri; "spec/fixture/#{myspace_name}.html"; end
  def replacement_gig_page_uri
    "spec/fixture/#{myspace_name}_gigs.html"
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
    Band.using_replacement_method(:page_uri) do
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
  it "should be the the URI of the band's gig page" do
    band = Band.new(:friend_id => '181410567', :title => "The D\303\270")
    gig_page_uri = "http://collect.myspace.com/index.cfm?fuseaction=bandprofile.listAllShows&friendid=181410567&n=The D\303\270"

    band.gig_page_uri.should.equal Band.new.uri(gig_page_uri)
  end
end

describe 'Band#load_band_info!' do
  Band.using_replacement_method(:page_uri) do
    it 'should extract the title and friend ID, returning the band' do
      band = Band.create(:myspace_name => 'thiswilldestroyyou').
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
  end
end

describe 'Band#load_gigs!' do
  Band.using_replacement_method(:gig_page_uri) do
    before do
      @band = Band.find_or_create(:myspace_name => 'royksopp')
      @band.load_gigs?
    end

    it 'should extract the time, title, and location' do
      @band.gigs.first.title.should.equal "R\303\266yksopp At Berns"
      @band.gigs.first.location.should.equal 'Berns'
      @band.gigs.first.time.
        should.equal Time.utc(2019, 10, 30, 20, 0, 0)
    end

    it 'should extract the address as a comma-separated list' do
      @band.gigs.first.address.
        should.equal "N\303\244ckstr\303\266msg. 8, Stockholm, 11147"
    end

    it "should return the band's gigs" do
      @band.load_gigs!.should.equal @band.gigs
    end

    it 'should not duplicate gigs' do
      @band.gigs.should.equal @band.load_gigs!
    end

    it 'should remove old gigs' do
      gig = Gig.create(:time => Time.now - 60)

      @band.add_gig(gig)
      @band.gigs.should.satisfy {|g| g.include?(gig)}

      @band.load_gigs!
      @band.gigs.should.satisfy {|g| !g.include?(gig)}
    end

    it "should update the gig's updated field if it's a new gig" do
      gig_updated = @band.gigs.first.updated

      @band.myspace_name = 'royksopp2'
      @band.load_gigs!

      @band.gigs.first.updated.should.equal gig_updated
      @band.gigs.sort_by {|g| g.updated}.last.
        should.satisfy {|g| g.updated > gig_updated}
    end
  end
end
