require 'helpers'

def filterable(root, feed=true)
  feed = '(/feed)?' if feed
  %r{^/#{root}/([^/?&#]+)(/=[\d]+)?(/=[^/?&#]+)?#{feed}/?$}
end

get '/ext/style.css' do
  sass :style
end

get '/' do
  @page_title = 'Giggregator'
  @gig_list = GigList.find_or_create(:title => '__all',
                                     :system => true)

  Band.each do |band|
    @gig_list.add_band(band) unless @gig_list.bands.include?(band)
  end

  haml :index
end

get filterable('gig-list') do
  retrieve_captures

  @gig_list = GigList[:link => @link, :system => nil]
  @page_title = @gig_list.title
  @page_feed = "#{self_link}feed/"
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => "/gig-list/#{@link}/edit/", :title => 'edit'},
     {:uri => @page_feed, :title => 'feed'},
    ]

  if @days or @location
    @breadcrumbs << {:uri => "/gig-list/#{@link}/", :title => 'reset'}
  end

  filter_gig_list

  @feed ? send_feed : haml(:gig_list)
end

get '/gig-list/:link/edit/?' do |link|
  @gig_list = GigList[:link => link]
  @page_title = @gig_list.title
  @page_feed = "/gig-list/#{link}/feed/"
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => "/gig-list/#{link}/", :title => 'view'},
     {:uri => "/gig-list/#{link}/feed/", :title => 'feed'},
    ]

  haml :edit_gig_list
end

get filterable('band') do
  retrieve_captures

  @band = Band.from_myspace(@link)
  @gig_list = @band.gig_list
  @page_title = @band.title
  @page_feed = "#{self_link}feed/"
  @title_by = 'band'
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => @band.page_uri, :title => 'band page'},
     {:uri => @band.gig_page_uri, :title => 'gig page'},
     {:uri => @page_feed, :title => 'feed'},
    ]

  if @days or @location
    @breadcrumbs << {:uri => "/band/#{@link}/", :title => 'reset'}
  end

  filter_gig_list

  @feed ? send_feed : haml(:band)
end

get '/band/:myspace_name/gig/:gig_id/?' do |myspace_name, gig_id|
  @gig = Gig.find(:id => gig_id)
  @gig_list = @gig.band.gig_list
  @page_title = @gig.band.title
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => "/band/#{myspace_name}/", :title => @gig.band.title},
    ]

  @scripts = ["http://maps.google.com/maps?file=api&v=2.x&key=#{GOOGLE_MAPS_API_KEY}",
              '/ext/map.js']

  haml :gig
end

post '/update-gig-list/?' do
  unless (gig_list = GigList[params[:id]])
    gig_list = GigList.create(:title => params[:title])
  end

  gig_list.remove_all_bands

  params[:band_list].split.each do |myspace_uri|
    Timeout::timeout(20) do
      gig_list.add_band(Band.from_myspace(myspace_uri))
    end
  end

  redirect "/gig-list/#{gig_list.link}/"
end

post '/filter-gig-list/?' do
  filters = [:days, :location].
    map {|f| "=#{params[f]}" unless params[f].strip.empty?}.
    compact

  if params[:link]
    dest = ['gig-list', params[:link]]
  else
    dest = ['band', params[:myspace_name]]
  end

  redirect build_link(*(dest + filters))
end
