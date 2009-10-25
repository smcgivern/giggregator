require 'spec/setup'
require 'lib/time_period'

describe 'TimePeriod.new' do
  it 'should require title and criteria' do
    time_period = TimePeriod.new(
                                 'Next minute',
                                 lambda {|t| t <= Time.now + 60}
                                 )

    time_period.title.should.equal 'Next minute'
    time_period.criteria[Time.now].should.be.true
    time_period.gigs.should.equal nil
  end
end

describe 'Days' do
  it 'should return a time n days in the future' do
    # May not work around midnight
    unless Days(1).day == 1
      Days(1).day.should.equal Time.now.day + 1
    else
      Days(1).day.should.equal 1
      Time.now.day.should.be.a {|d| d >= 28}
    end
  end
end
