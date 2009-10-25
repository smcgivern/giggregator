require 'spec/setup'
require 'time'

require 'model/gig'
require 'model/band'

describe 'Gig#time' do
  it 'should return the gig time in UTC' do
    def time(h, z); Time.xmlschema("2010-01-01T#{h}:00:00#{z}"); end

    Gig.new(:time => time('00', '-12:00')).time.
      should.equal time('12', 'Z')
  end
end

describe 'Gig#time_period' do
  it 'should be the first time period the gig matches' do
    TIME_PERIODS =
      [
       TimePeriod.new('The past', lambda {|t| t < Time.now}),
       TimePeriod.new('Next hour', lambda {|t| t <= Time.now + 3600}),
      ]

    gig = Gig.new(:time => Time.now)

    TIME_PERIODS.each {|t| t.criteria[gig.time].should.be.true}
    gig.time_period.should.equal TIME_PERIODS.first
  end
end

describe 'Gig#updated' do
  it "should return the band's gigs_updated field" do
    time = Time.utc(2009, 1, 1, 0, 0, 0)
    band = Band.create(:gigs_updated => time)
    gig = Gig.new
    band.add_gig(gig)

    gig.updated.should.equal time
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
  it 'should include the band title, the location, and the time' do
    def including?(t); lambda {|s| s.include?(t)}; end

    gig = Gig.create(:location => 'Stow',
                     :time => Time.utc(2009, 1, 1, 0, 0, 0))

    band = Band.create(:title => 'Honington')
    band.add_gig(gig)

    gig.title_by_time_period.should.be including?('Honington')
    gig.title_by_time_period.should.be including?('Stow')
    gig.title_by_time_period.should.be including?('12:00 AM')
  end
end
