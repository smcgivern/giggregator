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

get '/' do
  @gig_list = GigList.find_or_create(:title => '__all',
                                     :system => true)

  @gig_list.remove_all_bands

  Band.each {|b| @gig_list.add_band(b)}

  haml :index
end

get '/gig-list/:link/?' do |link|
  @gig_list = GigList[:link => link]

  haml :gig_list
end

get '/gig-list/:link/edit/?' do |link|
  @gig_list = GigList[:link => link]

  haml :edit_gig_list
end

get '/gig-list/:link/feed/?' do |link|
  gig_list = GigList[:link => link]
  gig_list.generate_feed?

  send_file gig_list.feed_filename
end

get '/band/:myspace_name/?' do |myspace_name|
  @band = Band.from_myspace(myspace_name)

  haml :band
end

post '/update-gig-list/?' do
  unless (gig_list = GigList[params[:id]])
    gig_list = GigList.create(:title => params[:title])
  end

  gig_list.remove_all_bands

  params[:band_list].split.each do |myspace_url|
    Timeout::timeout(20) do
      begin
        gig_list.add_band(Band.from_myspace(myspace_url))
      rescue NotABandError, Timeout::Error
      end
    end
  end

  redirect("/gig-list/#{gig_list.link}/")
end
