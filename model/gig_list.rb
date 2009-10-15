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

  def slug
    title.
      downcase.
      gsub(/([a-z0-9])(\.|'([a-z0-9]))/, '\1\3').
      gsub(/[^a-z0-9]+/, '-')
  end

  def before_save
    def slug_i(i); "#{slug}-#{i}"; end

    attempt = slug; i = 0

    while GigList[:link => attempt] do attempt = slug_i(i += 1) end

    set(:link => attempt)
  end

  def myspace_urls; bands.map {|b| b.page_uri}.join("\n"); end
  def gig_list; bands.map {|b| b.gigs}.flatten; end
  def by_time; gig_list.sort_by {|g| g.time}; end
  def updated; by_time.last.time; end

  def group_by_time_period
    TIME_PERIODS.dup.map do |period|
      period.gigs = by_time.select {|g| period == g.time_period}
      period
    end
  end

  def feed_filename; File.join(FEED_DIR, "#{link}.atom"); end

  def generate_feed?
    generate_feed! unless (File.exist?(feed_filename) &&
                           File.stat(feed_filename).mtime < updated)
  end

  def generate_feed!
    feed = FeedTools::Feed.new
    entry = FeedTools::FeedItem.new

    feed.link = "#{ROOT_URL}/gig-list/#{link}/feed/"
    feed.title = title
    feed.updated = updated
    feed.author = 'Giggregator'

    entry.link = "#{ROOT_URL}/gig-list/#{link}/feed/"
    entry.title = title
    entry.content = by_time.map {|g| g.title}.join('<br>')
    entry.updated = updated

    feed.entries = [entry]

    open(feed_filename, 'w').puts(feed.build_xml)
  end
end
