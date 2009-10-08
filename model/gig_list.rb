class GigList
  def <<(gigs); @gig_list + gigs; end

  def by_time_period
    # gigs.by_time_period returns a hash like:
    # {
    #   :next_week => [gig1, gig2],
    #   :next_month => [gig3, gig4],
    #   :all_time => [gig5],
    # }
    #
    # Doesn't work -- there's no ordering, and no names for the time
    # periods.

    gigs.keys.sort_by {|t| t.sort_index}.each do |time_period|
      puts time_period.title

      gigs[time_period].sort_by {|g| g.time}.each do |gig|
        puts gig.title
      end
    end
  end
end
