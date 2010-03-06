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

describe 'TimePeriod.==' do
  it 'should return true if all attributes are equal' do
    time_period = TimePeriod.new('Equality test', lambda {|t| true})

    time_period.dup.should.equal time_period
    time_period.dup.should.not {|t| t === time_period}
  end
end

describe 'TimePeriod.css' do
  it 'should be a version of the title suitable for use in CSS' do
    time_period = TimePeriod.new('CSS class test', lambda {|t| true})

    time_period.css.should.equal 'css-class-test'
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

describe 'Between' do
  it 'should check that the time is between the two days' do
    Between(Time.now, -1, 1).should.be.true
    Between(Time.now, 1, 2).should.be.false
    Between(Days(-2), -3, -1).should.be.true
  end

  it 'should allow both second and third arguments to be nil' do
    Between(Time.now, -1).should.be.true
    Between(Time.now, nil, 2).should.be.true
  end
end
