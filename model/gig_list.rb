require 'lib/model'

class GigList < Sequel::Model
  many_to_many :bands
  attr_accessor :filters

  create_schema do
    primary_key(:id)
    Boolean(:system)
    String(:title)
    String(:link, :unique => true)
    String(:openid)
    DateTime(:accessed)
  end

  def initialize(*args); @filters ||= {}; super(*args); end

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
  def by(c); gig_list.sort_by {|g| g.send(c)}; end
  def by_time; by(:time); end
  def clear_cached_gig_list; @gig_list = nil; end

  def updated
    latest = (gig_list.map {|g| g.updated} + [accessed]).compact.max

    if latest < Days(-7)
      latest = Time.now
      set(:accessed => latest)
      save
    end

    latest
  end


  def gig_list
    return @gig_list if @gig_list

    @gig_list = bands.
      map {|b| b.gigs}.
      flatten.
      delete_if {|g| g.time <= Time.now}

    @filters.each do |type, value|
      next unless value

      @gig_list =
        case type
        when :days: days_filter(value.to_i)
        when :location: location_filter(value)
        else @gig_list
        end
    end

    @gig_list
  end

  def days_filter(days)
    @gig_list.map {|g| g if g.time <= Days(days)}.compact
  end

  def location_filter(locations)
    @gig_list.map do |gig|
      if ([:title, :location, :address].any? do |col|
            locations.split.any? do |loc|
              if (src = gig.send(col))
                src.downcase.include?(loc.downcase)
              end
            end
          end)
        gig
      end
    end.compact
  end

  def group_by_time_period(col=:time)
    TIME_PERIODS.map do |period|
      period = period.dup
      period.gigs = by(col).select {|g| period == g.time_period(col)}
      period
    end.reject {|p| p.gigs.empty?}
  end
end
