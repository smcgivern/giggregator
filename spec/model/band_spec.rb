require 'model/band'

def type(constant); lambda {|x| constant === x}; end

describe 'Band.from_myspace' do
end

describe 'Band#uri' do
  it 'should convert a string to an Addressable URI' do
    Band.new.uri('').
      should.be.a type(Addressable::URI)
  end
end

describe 'Band#parse' do
  before {@doc = Band.new.parse('spec/fixture/nokogiri.html')}

  it 'should use Nokogiri to parse the filename given' do
    @doc.should.be.a type(Nokogiri::HTML::Document)
  end

  it 'should use UTF-8 encoding' do
    @doc.at('title').inner_text.should.equal "The D\303\270"
  end
end

describe 'Band#page_uri' do
end

describe 'Band#gig_page_uri' do
end

describe 'Band#load_band_info' do
end

describe 'Band#load_gigs' do
end
