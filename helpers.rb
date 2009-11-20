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

  def u(s); Addressable::URI.encode(s.gsub(' ', '+')); end
  def rp(s); RubyPants.new(s.gsub(' - ', ' -- ')).to_html; end
  def ts(s); u("#{s}#{'/' unless s =~ /\/$/}"); end

  def self_base_uri; ts(self_uri.gsub(self_link, '')); end
  def self_uri; ts(request.url); end
  def self_link; ts(request.fullpath); end

  def build_link(*parts)
    "#{@feed ? self_base_uri : '/'}#{ts(parts.compact.join('/'))}"
  end

  def gig_link(gig)
    build_link('band', gig.band.myspace_name, 'gig', gig.id)
  end

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
        when /^\/=/: @location = capture.gsub(/^\/=/, '')
        when '/feed': @feed = true
        else @link = capture
        end
      end
    end
  end

  def filter_gig_list
    [:days, :location].each do |field|
      if (value = instance_variable_get("@#{field}"))
        @gig_list.filters[field] = value
      end
    end
  end

  def send_feed
    @inline_style = 'list-style-type : none'

    last_modified(@gig_list.updated)
    haml(:feed_gig_list, :format => :xhtml, :layout => false)
  end
end
