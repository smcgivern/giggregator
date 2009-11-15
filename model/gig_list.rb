require 'lib/model'

class GigList < Sequel::Model
  many_to_many :bands

  create_schema do
    primary_key(:id)
    Boolean(:system)
    String(:title)
    String(:link, :unique => true)
  end

  def validate
    if title =~ /\A__/ and !system
      errors[:title] << "can't start with two underscores"
    end
  end

  def slug(i=nil)
    (title || '').
      downcase.
      gsub(/([a-z0-9])(\.|'([a-z0-9]))/, '\1\3').
      gsub(/[^a-z0-9]+/, '-') +
      (i ? "-#{i}" : '')
  end

  def before_save
    return unless (link.nil? || link.empty?)

    attempt = slug; i = 0

    while GigList[:link => attempt] do attempt = slug(i += 1) end

    set(:link => attempt)
  end

  def myspace_uris; bands.map {|b| b.page_uri}.join("\n"); end
  def by_time; gig_list.sort_by {|g| g.time}; end
  def updated; gig_list.sort_by {|g| g.updated}.last.updated; end

  def filter_by_location!(loc)
    gig_list.delete_if do |gig|
      !([:title, :location, :address].any? do |col|
          gig.send(col).downcase.include?(loc.downcase)
        end)
    end
  end

  def gig_list
    return @gig_list if @gig_list

    @gig_list = bands.
      map {|b| b.gigs}.
      flatten.
      delete_if {|g| g.time <= Time.now}
  end

  def group_by_time_period
    TIME_PERIODS.map do |period|
      period = period.dup
      period.gigs = by_time.select {|g| period == g.time_period}
      period
    end.reject {|p| p.gigs.empty?}
  end
end
