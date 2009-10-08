class TimePeriod
  attr_accessor :index, :title, :criteria

  def initialize; yield self if block_given?; end
end
