set :haml, {:format => :html5}
set :views, "#{File.dirname(__FILE__)}/view"

before do
  request_type = case request.env['REQUEST_URI']
                 when /\.css$/ : :css
#                 when /\/feed\/?$/ : :atom
                 else :html
                 end

  content_type CONTENT_TYPES[request_type], :charset => 'utf-8'
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def rp(s); RubyPants.new(s.gsub(' - ', ' -- ')).to_html; end
  def ts(s); "#{s}#{'/' unless s =~ /\/$/}"; end

  def self_base_uri; ts(self_uri.gsub(self_link, '')); end
  def self_uri; ts(request.url); end
  def self_link; ts(request.fullpath); end

  def default_breadcrumbs
    [{:uri => '/', :title => 'Giggregator'}]
  end

  def show_breadcrumbs(breadcrumbs)
    breadcrumbs.
      map {|b| "<a href=\"#{b[:uri]}\">#{rp(b[:title])}</a>"}.
      join(' / ')
  end

  def retrieve_captures
    if (captures = params[:captures])
      captures.compact.each do |capture|
        case capture
        when /^\/=([\d]+)/: @days = capture.gsub(/^\/=/, '')
        when /^\/=/: @text_search = capture.gsub(/^\/=/, '')
        when '/feed': @feed = true
        else @link = capture
        end
      end
    end
  end
end
