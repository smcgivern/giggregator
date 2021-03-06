require './spec/setup'
require 'time'

require './model/gig'

require './spec/time_periods'

def including?(t); lambda {|s| s.include?(t)}; end

describe 'Gig#time' do
  it 'should return the gig time in UTC' do
    def time(h, z); Time.xmlschema("2010-01-01T#{h}:00:00#{z}"); end

    Gig.new(:time => time('00', '-12:00')).time.
      should.equal time('12', 'Z')
  end
end

describe 'Gig#time_period' do
  it 'should be the first time period the gig matches' do
    gig = Gig.new(:time => Time.now)

    TIME_PERIODS.each {|t| t.criteria[gig.time].should.be.true}
    gig.time_period.should.equal TIME_PERIODS.first
  end

  it 'should use another column if specified' do
    gig = Gig.new(:updated => Time.now + 60)

    gig.time_period(:updated).should.equal TIME_PERIODS.last
  end
end

describe 'Gig#format_time' do
  before {@gig = Gig.new(:time => Time.utc(2009, 1, 1, 0, 0, 0))}

  it 'should format the time using the supplied format' do
    @gig.format_time('%Y').should.equal '2009'
    @gig.format_time('%Y-%p').should.equal '2009-AM'
  end

  it 'should strip leading zeroes' do
    @gig.format_time('%d %m').should.equal '1 1'
  end
end

describe 'Gig#strip_leading_zeroes' do
  it 'should remove zeroes after spaces and before other digits' do
    Gig.new.strip_leading_zeroes('1 01 01').should.equal '1 1 1'
    Gig.new.strip_leading_zeroes('1 0a 0a').should.equal '1 0a 0a'
    Gig.new.strip_leading_zeroes('1-01-01').should.equal '1-01-01'
  end

  it 'should remove zeroes at the start' do
    Gig.new.strip_leading_zeroes('01 01 01').should.equal '1 1 1'
    Gig.new.strip_leading_zeroes('01 0a 0a').should.equal '1 0a 0a'
    Gig.new.strip_leading_zeroes('01-01-01').should.equal '1-01-01'
  end
end

describe 'Gig#time_formatted' do
  it 'should format the time using the format TIME_FORMAT' do
    gig = Gig.new(:time => Time.utc(2009, 1, 1, 0, 0, 0))
    gig.time_formatted.should.equal gig.format_time(Gig::TIME_FORMAT)
  end
end

describe 'Gig#date_formatted' do
  it 'should format the time using the format DATE_FORMAT' do
    gig = Gig.new(:time => Time.utc(2009, 1, 1, 0, 0, 0))
    gig.date_formatted.should.equal gig.format_time(Gig::DATE_FORMAT)
  end
end

describe 'Gig#title_by_time_period' do
  it 'should include the band title, the address, and the date' do
    gig = Gig.create(:address => 'Stow',
                     :time => Time.utc(2009, 1, 1, 0, 0, 0))

    band = Band.create(:title => 'Honington')
    band.add_gig(gig)

    gig.title_by_time_period.should.be including?('Honington')
    gig.title_by_time_period.should.be including?('Stow')
    gig.title_by_time_period.should.be including?('Jan 2009')
  end
end

describe 'Gig#title_by_band' do
  it 'should include the address and the date' do
    gig = Gig.create(:address => 'Edgehill',
                     :time => Time.utc(2009, 1, 1, 0, 0, 0))

    band = Band.create(:title => 'Compton Verney')
    band.add_gig(gig)

    gig.title_by_band.should.be including?('Edgehill')
    gig.title_by_band.should.not.be including?('Compton Verney')
    gig.title_by_band.should.be including?('Jan 2009')
  end
end

describe 'Gig#event_id' do
  it 'should be a stringified version of the event ID' do
    gig_a = Gig.create(:event_id => 1)
    gig_b = Gig.create(:event_id => BigDecimal.new('111111111111111'))

    gig_a.event_id.should.equal '1'
    gig_b.event_id.should.equal '111111111111111'
  end
end

describe 'Gig#uri' do
  it 'should link to the gig page on Myspace' do
    gig = Gig.create(:event_id => 1, :title => 'Foo')

    gig.uri.to_s.
      should.equal 'https://www.myspace.com/events/View/1/Foo'
  end

  it 'should be nil when there is no event ID' do
    gig = Gig.create
    gig.uri.should.equal nil
  end
end
