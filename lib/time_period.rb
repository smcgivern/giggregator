class TimePeriod
  attr_accessor :title, :criteria, :gigs

  def initialize(title, criteria)
    @title = title
    @criteria = criteria

    yield self if block_given?
  end
end

def Days(n); Time.now + (n * 60 * 60 * 24); end
