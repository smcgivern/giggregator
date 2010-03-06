require 'helpers'

def filterable(root)
  %r{^/#{root}/([^/?&#]+)(/=[\d]+)?(/=[^/?&#]+)?(/freshness)?(/feed)?/?$}
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
  mappable

  @gig_list = GigList[:link => @link, :system => nil]
  @page_title = @gig_list.title
  @page_feed = "#{self_link}feed/"
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => "/gig-list/#{@link}/edit/", :title => 'edit'},
     {:uri => @page_feed, :title => 'feed'},
    ]

  @breadcrumbs << {
    :uri => "#{self_link}freshness/", :title => 'freshness'
  } unless @freshness

  if @days or @location or @freshness
    @breadcrumbs << {:uri => "/gig-list/#{@link}/", :title => 'reset'}
  end

  filter_gig_list

  @feed ? send_feed : haml(:gig_list)
end

get filterable('band') do
  retrieve_captures
  mappable

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

  @breadcrumbs << {
    :uri => "#{self_link}freshness/", :title => 'freshness'
  } unless @freshness

  if @days or @location or @freshness
    @breadcrumbs << {:uri => "/band/#{@link}/", :title => 'reset'}
  end

  filter_gig_list

  @feed ? send_feed : haml(:band)
end

get '/band/:myspace_name/gig/:gig_id/?' do |myspace_name, gig_id|
  mappable

  @gig = Gig.find(:id => gig_id)
  @gig_list = @gig.band.gig_list
  @page_title = @gig.band.title
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => "/band/#{myspace_name}/", :title => @gig.band.title},
    ]

  haml :gig
end


get %r{^/gig-list/([^/?&#]+)/edit(/logged-in)?/?$} do
  link, @logged_in = params[:captures]

  @gig_list = GigList[:link => link]
  @page_title = @gig_list.title
  @page_feed = "/gig-list/#{link}/feed/"
  @breadcrumbs = default_breadcrumbs +
    [
     {:uri => "/gig-list/#{link}/", :title => 'view'},
     {:uri => "/gig-list/#{link}/feed/", :title => 'feed'},
    ]

  if @logged_in
    params.delete('captures')
    oidresp = openid_consumer.complete(params, request.url)

    if oidresp.status == OpenID::Consumer::SUCCESS
      session[:openid] = oidresp.display_identifier
      redirect build_link('gig-list', link, 'edit')
    else
      @login_failure = true
    end
  end

  if @login_failure or
      (!((openid = @gig_list.openid) || '').empty? &&
       openid != session[:openid])

    haml :login_edit_gig_list
  else
    haml :edit_gig_list
  end
end

post '/update-gig-list/?' do
  unless (gig_list = GigList[params[:id]])
    gig_list = GigList.create(:title => params[:title])
  end

  if ((openid = (gig_list.openid || '')).empty? ||
      (openid == session[:openid]))

    gig_list.title = params[:title]
    gig_list.openid = params[:openid_uri]
    gig_list.save
    gig_list.remove_all_bands

    params[:band_list].split.each do |myspace_uri|
      Timeout::timeout(20) do
        gig_list.add_band(Band.from_myspace(myspace_uri))
      end
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

post '/openid-login/?' do
  dest = ['gig-list', params[:link], 'edit', 'logged-in']

  begin
    oidreq = openid_consumer.begin(params[:openid_uri])
  rescue OpenID::DiscoveryFailure
    redirect build_link(*dest)
  else
    @feed = true
    redirect oidreq.redirect_url(self_base_uri, build_link(*dest))
  end
end
