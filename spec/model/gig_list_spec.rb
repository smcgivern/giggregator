require 'spec/setup'

require 'model/band'
require 'model/bands_gig_list'
require 'model/gig'
require 'model/gig_list'

def mock_band(myspace_name, time=Time.now)
  Band.create(:myspace_name => myspace_name, :gigs_updated => time)
end

describe 'GigList#validate' do
  it 'should disallow names starting with __' do
    should.raise(Sequel::ValidationFailed) do
      GigList.create(:title => '__test')
    end
  end

  it 'should allow those names if the system flag is set' do
    should.not.raise(Sequel::ValidationFailed) do
      GigList.create(:title => '__test', :system => true)
    end
  end
end

describe 'GigList#slug' do
  def slug(s, i=nil); GigList.create(:title => s).slug(i); end

  it 'should only be in lower case' do
    slug('Debreceni VSC').should.equal 'debreceni-vsc'
  end

  it 'should remove apostrophes in words' do
    slug("Eat at Joe's").should.equal 'eat-at-joes'
  end

  it 'should remove full stops after letters' do
    slug('A.F.C. Wimbledon...semi-professional').
      should.equal 'afc-wimbledon-semi-professional'
  end

  it 'should replace all other punctuation' do
    slug('src/lib/slug').should.equal 'src-lib-slug'
  end

  it 'should fold multiple non-slug characters' do
    slug('e^{i \pi} + 1 = 0').should.equal 'e-i-pi-1-0'
  end

  it 'should append the index, if given' do
    slug('Debreceni VSC', 1).should.equal 'debreceni-vsc-1'
  end
end

describe 'GigList#before_save' do
end

describe 'GigList#myspace_uris' do
  it 'should be a list of MySpace URIs, one per line' do
    gig_list = GigList.create
    myspace_names = ['lorem', 'ipsum', 'dolor', 'sit', 'amet']
    exp = myspace_names.map {|m| "http://www.myspace.com/#{m}"}.sort

    myspace_names.each {|m| gig_list.add_band(mock_band(m))}

    gig_list.myspace_uris.split("\n").sort.should.equal exp
  end
end

describe 'GigList#by_time' do
  it 'should be sorted by time, oldest first' do
    gig_list = GigList.create
    band = mock_band('by_time')

    expected = [1, 2, 3].map do |i|
      band.add_gig(Gig.create(:time => Time.now + (600 - 60 * i),
                              :title => "Gig #{i}"))
    end

    gig_list.add_band(band)

    gig_list.by_time.should.equal expected.reverse
  end
end

describe 'GigList#updated' do
  it 'should be the latest gigs_updated for all bands in the list' do
    gig_list = GigList.create

    expected = [1, 2, 3].map do |i|
      time = Time.now + (60 * i)

      gig_list.add_band(mock_band("updated-#{i}", time))
      time
    end

    gig_list.updated.should.equal expected.sort.last
  end
end

describe 'GigList#gig_list' do
  it 'should be the gigs belonging to the bands in the gig list' do
    gig_list = GigList.create

    expected = [1, 2, 3].map do |i|
      band = mock_band("gig_list-#{i}")
      gig_list.add_band(band)

      [4, 5, 6].map do |j|
        band.add_gig(Gig.create(:time => Time.now + (600 * i + j),
                                :title => "Gig #{j}"))
      end
    end.flatten

    gig_list.gig_list.should.equal expected
  end

  it 'should exclude gigs in the past' do
    gig_list = GigList.create
    band = mock_band('gig_list')

    gig_list.add_band(band)
    band.add_gig(Gig.create(:time => Time.now - 60,
                            :title => 'Test gig'))

    gig_list.gig_list.should.equal []
  end
end

describe 'GigList#group_by_time_period' do
  before do
    @gig_list = GigList.create
    @band = mock_band("group_by_time_period-#{rand}")
    @gig_list.add_band(@band)
  end

  def add_gig(t); @band.add_gig(Gig.create(:time => t)); end

  it 'should return a list of time periods and their matching gigs' do
    expected = [
     Time.now + 60, Days(2), Days(8), Days(40)
    ].map {|t| [add_gig(t)]}

    @gig_list.group_by_time_period.map {|p| p.gigs}.
      should.equal [expected.first]
  end

  it 'should use the time periods in TIME_PERIODS' do
    original = TIME_PERIODS[0]
    TIME_PERIODS[0] = TimePeriod.new('Any time', lambda {|t| true})

    expected = [7, 8, 9].map {|i| add_gig(Time.now + 60 * i)}
    grouped_by_time_period = @gig_list.group_by_time_period

    grouped_by_time_period.length.should.equal 1
    grouped_by_time_period.first.title.should.equal 'Any time'
    grouped_by_time_period.first.gigs.should.equal expected

    TIME_PERIODS[0] = original
  end

  it 'should exclude time periods with no gigs' do
    time_period = TIME_PERIODS[1].dup

    @band.add_gig(Gig.create(:time => Time.now + 60))
    time_period.gigs = @band.gigs

    @gig_list.group_by_time_period.should.equal [time_period]
  end
end
