require 'lib/time_period'

TIME_PERIODS =
  [
   TimePeriod.new('The past', lambda {|t| t < Time.now}),
   TimePeriod.new('Next hour', lambda {|t| t <= Time.now + 3600}),
  ]
