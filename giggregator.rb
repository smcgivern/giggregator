require 'haml'
require 'sinatra'

require 'setup'

set :haml, {:format => :html5}

get '/' do
  haml :index
end

get '/band/:myspace_name/?' do
  @band = Band.from_myspace(params[:myspace_name])
  haml :band
end
