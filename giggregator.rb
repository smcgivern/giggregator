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

  [:days, :filter].each do |field|
    if (value = instance_variable_get("@#{f}"))
      @gig_list.filters[field] = value
    end
  end

  if @feed
    @inline_style = 'list-style-type : none'

    return haml(:feed_gig_list, :format => :xhtml, :layout => false)
  end

  @page_title = @gig_list.title
  @page_feed = "#{self_link}feed/"
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => "/gig-list/#{@link}/edit/", :title => 'edit'},
     {:uri => @page_feed, :title => 'feed'},
    ]

  if @days or @filter
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
  @page_title = @band.title
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => @band.page_uri, :title => 'band page'},
     {:uri => @band.gig_page_uri, :title => 'gig page'},
    ]

  haml :band
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
