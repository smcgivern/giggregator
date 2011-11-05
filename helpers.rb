set :haml, {:format => :html5}
set :views, "#{File.dirname(__FILE__)}/view"
enable :sessions

before do
  request_type = case request.env['REQUEST_URI']
                 when /\.css$/ : :css
                 when /\/feed\/?$/ : :atom
                 else :html
                 end

  content_type CONTENT_TYPES[request_type], :charset => 'utf-8'

  @col = :time
end

module GiggregatorHelpers
  def r(s)
    (s =~ /^\// && !(s =~ /^\/#{ROOT}/)) ? "/#{ROOT}#{s}" : s
  end
  module_function :r

  def u(s); Addressable::URI.encode(s.gsub(' ', '+')); end
  def rp(s); RubyPants.new(s.gsub(' - ', ' -- ')).to_html; end
  def ts(s); u("#{s}#{'/' unless s =~ /\/$/}"); end

  def self_uri; ts(request.url); end
  def self_link; ts(request.fullpath); end

  def self_base_uri
    ts(self_uri.gsub(self_link, '')) + (ROOT ? "#{ROOT}/" : '')
  end

  def self_domain
    self_base_uri.gsub('http://', '').split('/').first
  end

  def build_link(*parts)
    r("#{@feed ? self_base_uri : '/'}#{ts(parts.compact.join('/'))}")
  end

  def updated_class?(gig, gig_list)
    gig.updated > (gig_list.updated - 60) ? {:class => 'updated'} : {}
  end

  def atom_entry_id(gig_list)
    ['tag',
     "#{self_domain},#{gig_list.updated.strftime('%Y-%m-%d')}",
     self_link.gsub('/feed', '')
    ].join(':')
  end

  def gig_link(gig)
    build_link('band', gig.band.myspace_name, 'gig', gig.id)
  end

  def default_breadcrumbs
    [{:uri => '/', :title => 'Home / about'}]
  end

  def show_breadcrumbs(breadcrumbs)
    breadcrumbs.
      map {|b| "<a href=\"#{r(b[:uri])}\">#{rp(b[:title])}</a>"}.
      join(' / ')
  end

  def retrieve_captures
    if (captures = params[:captures])
      captures.compact.each do |capture|
        case capture
        when /^\/=([\d]+)/: @days = capture.gsub(/^\/=/, '')
        when /^\/=/: @location = capture.gsub(/^\/=/, '')
        when '/freshness': @col = :updated; @freshness = true
        when '/feed': @feed = true
        else @link = capture
        end
      end
    end
  end

  def openid_consumer
    return @openid_consumer if @openid_consumer

    store = OpenID::Store::Filesystem.new(OPENID_STORE)
    @openid_consumer = OpenID::Consumer.new(session, store)
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

  def mappable; @scripts = [GOOGLE_MAPS_SCRIPT, '/ext/map.js']; end
end

helpers GiggregatorHelpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

module Sass::Script::Functions
  def r(s)
    Sass::Script::String.new(GiggregatorHelpers.r(s.value))
  end
end
