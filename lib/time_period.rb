class TimePeriod
  attr_accessor :title, :criteria, :gigs

  def initialize(title, criteria)
    @title = title
    @criteria = criteria

    yield self if block_given?
  end

  def ==(other)
    [:title, :criteria, :gigs].map {|a| send(a) == other.send(a)}.all?
  end
end

def Days(n); Time.now + (n * 60 * 60 * 24); end
