require 'helpers'

get '/style.css' do
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

get %r{^/gig-list/([^/?&#]+)(/=[\d]+)?(/=[^/?&#]+)?(/feed)?/?$} do
  retrieve_captures

  @gig_list = GigList[:link => @link, :system => nil]

  [:days, :location].each do |field|
    if (value = instance_variable_get("@#{field}"))
      @gig_list.filters[field] = value
    end
  end

  if @feed
    @inline_style = 'list-style-type : none'

    last_modified(@gig_list.updated)
    return haml(:feed_gig_list, :format => :xhtml, :layout => false)
  end

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

  haml :gig_list
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

get '/band/:myspace_name/?' do |myspace_name|
  @band = Band.from_myspace(myspace_name)
  @gig_list = @band.gig_list
  @page_title = @band.title
  @title_by = 'band'
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => @band.page_uri, :title => 'band page'},
     {:uri => @band.gig_page_uri, :title => 'gig page'},
    ]

  haml :band
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
              '/map.js']

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

  dest = (['gig-list', GigList[params[:id]].link] + filters).join('/')

  redirect u("/#{dest}/")
end
