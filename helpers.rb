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
  include Rack::Utils
  alias_method :h, :escape_html

  def rp(s); RubyPants.new(h(s).gsub(' - ', ' -- ')).to_html; end
  def self_link; request.url; end

  def default_breadcrumbs
    [{:uri => '/', :title => 'Giggregator'}]
  end

  def show_breadcrumbs(breadcrumbs)
    breadcrumbs.
      map {|b| "<a href=\"#{b[:uri]}\">#{rp(b[:title])}</a>"}.
      join(' / ')
  end
end
