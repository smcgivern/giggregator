require 'lib/model'

require 'digest/md5'

class GigList < Sequel::Model
  many_to_many :bands

  create_schema :no_timestamp do
    primary_key(:id)
    String(:title)
    String(:link, :unique => true)
  end

  def slug
    title.
      downcase.
      gsub(/([a-z0-9])(\.|'([a-z0-9]))/, '\1\3').
      gsub(/[^a-z0-9]+/, '-')
  end

  def before_save
    def slug_i(i); "#{slug}-#{i}"; end

    attempted_link = slug
    i = 0

    while GigList[:link => attempted_link] do
      attempted_link = slug_i(i += 1)
    end

    set(:link => attempted_link)
  end

  def myspace_urls; bands.map {|b| b.page_uri}.join("\n"); end
  def gig_list; bands.map {|b| b.gigs}.flatten; end

  def by_time
    gig_list.sort_by {|g| g.time}
  end

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
