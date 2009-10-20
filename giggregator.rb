set :haml, {:format => :html5}

before do
  request_type = case request.env['REQUEST_URI']
                 when /\.css$/ : :css
                 when /\.js$/ : :js
                 when /\/feed\/?$/ : :atom
                 else :html
                 end

  content_type CONTENT_TYPES[request_type], :charset => 'utf-8'
end

helpers do
  def show_breadcrumbs(breadcrumbs)
    breadcrumbs.
      map {|b| "<a href=\"#{b[:uri]}\">#{b[:title]}</a>"}.
      join(' / ')
  end

  def default_breadcrumbs
    [{:uri => '/', :title => 'Giggregator'}]
  end

  def rubypants(s); RubyPants.new(s).to_html; end
end

get '/' do
  @page_title = 'Giggregator'
  @gig_list = GigList.find_or_create(:title => '__all',
                                     :system => true)

  @gig_list.remove_all_bands

  Band.each {|b| @gig_list.add_band(b)}

  haml :index
end

get '/style.css' do
  sass :style
end

get '/gig-list/:link/?' do |link|
  @gig_list = GigList[:link => link]
  @page_title = @gig_list.title
  @page_feed = "/gig-list/#{link}/feed/"
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => "/gig-list/#{link}/edit/", :title => 'edit'},
     {:uri => "/gig-list/#{link}/feed/", :title => 'feed'},
    ]

  haml :gig_list
end

get '/gig-list/:link/edit/?' do |link|
  @gig_list = GigList[:link => link]
  @page_title = @gig_list.title
  @page_feed = "/gig-list/#{link}/feed/"
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => "/gig-list/#{link}/edit/", :title => 'edit'},
     {:uri => "/gig-list/#{link}/feed/", :title => 'feed'},
    ]

  haml :edit_gig_list
end

get '/gig-list/:link/feed/?' do |link|
  gig_list = GigList[:link => link]
  gig_list.generate_feed?

  send_file gig_list.feed_filename
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

  params[:band_list].split.each do |myspace_url|
    Timeout::timeout(20) do
      gig_list.add_band(Band.from_myspace(myspace_url))
    end
  end

  redirect("/gig-list/#{gig_list.link}/")
end
