require 'setup'

require 'haml'
require 'sinatra'
require 'timeout'

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

def url_for(*cs); "#{url_for_ts(*cs)}/"; end
def url_for_ts(*cs); "#{ROOT_DIR}/#{cs.join('/')}"; end

get '/' do
  haml :index
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

  redirect(url_for('gig-list', gig_list.link))
end

get '/gig-list/:link/?' do |link|
  @gig_list = GigList[:link => link]

  haml :gig_list
end

get '/gig-list/:link/edit/?' do |link|
  @gig_list = GigList[:link => link]

  haml :edit_gig_list
end

get '/band/:myspace_name/?' do |myspace_name|
  @band = Band.from_myspace(myspace_name)

  haml :band
end
