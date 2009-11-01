set :haml, {:format => :html5}
set :views, "#{File.dirname(__FILE__)}/view"

before do
  request_type = case request.env['REQUEST_URI']
                 when /\.css$/ : :css
                 when /\/feed\/?$/ : :atom
                 else :html
                 end

  content_type CONTENT_TYPES[request_type], :charset => 'utf-8'
end

helpers do
  def show_breadcrumbs(breadcrumbs)
    breadcrumbs.
      map {|b| "<a href=\"#{b[:uri]}\">#{rp(b[:title])}</a>"}.
      join(' / ')
  end

  def default_breadcrumbs;
    [{:uri => '/', :title => 'Giggregator'}]
  end

  def rp(s); RubyPants.new(s.gsub(' - ', ' -- ')).to_html; end
end

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

get '/gig-list/:link/?' do |link|
  @gig_list = GigList[:link => link, :system => false]
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
     {:uri => "/gig-list/#{link}/", :title => 'view'},
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

  params[:band_list].split.each do |myspace_uri|
    Timeout::timeout(20) do
      gig_list.add_band(Band.from_myspace(myspace_uri))
    end
  end

  redirect("/gig-list/#{gig_list.link}/")
end
