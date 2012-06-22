require 'test_helper'
require 'roar/representer/feature/http_verbs'
require 'roar/representer/json'

class HttpVerbsTest < MiniTest::Spec
  BandRepresenter = FakeServer::BandRepresenter
  
  # keep this class clear of Roar modules.
  class Band
    attr_accessor :name, :label
  end
  
  
  describe "HttpVerbs" do
    before do
      @band = Band.new
      @band.extend(BandRepresenter)
      @band.extend(Roar::Representer::Feature::HttpVerbs)
    end
    
    describe "transport_engine" do
      before do
        @http_verbs = Roar::Representer::Feature::HttpVerbs
        @net_http   = Roar::Representer::Transport::NetHTTP
      end
      
      it "has a default set in the transport module level" do
        assert_equal @net_http, @band.transport_engine
      end
      
      it "allows changing on instance level" do
        @band.transport_engine = :soap
        assert_equal @net_http, @http_verbs.transport_engine
        assert_equal :soap, @band.transport_engine
      end
    end
    
    
    describe "HttpVerbs.get" do
      it "returns instance from incoming representation" do
        band = @band.get("http://roar.example.com/bands/slayer", "application/json")
        assert_equal "Slayer", band.name
        assert_equal "Canadian Maple", band.label
      end

      # FIXME: move to faraday test.
      describe 'a non-existent resource' do
        it 'handles HTTP errors and raises a ResourceNotFound error with FaradayHttpTransport' do
          @band.transport_engine = Roar::Representer::Transport::Faraday
          assert_raises(::Faraday::Error::ResourceNotFound) do
            @band.get('http://roar.example.com/bands/anthrax', "application/json")
          end
        end

        it 'performs no HTTP error handling with NetHttpTransport' do
          @band.transport_engine = Roar::Representer::Transport::NetHTTP
          assert_raises(JSON::ParserError) do
            @band.get('http://roar.example.com/bands/anthrax', "application/json")
          end
        end
      end
    end

    describe "#get" do
      it "updates instance with incoming representation" do
        @band.get("http://roar.example.com/bands/slayer", "application/json")
        assert_equal "Slayer", @band.name
        assert_equal "Canadian Maple", @band.label
      end
    end
    
    describe "#post" do
      it "updates instance with incoming representation" do
        @band.name = "Strung Out"
        assert_equal nil, @band.label
        
        @band.post("http://roar.example.com/bands", "application/xml")
        assert_equal "STRUNG OUT", @band.name
        assert_equal nil, @band.label
      end
    end
    
    describe "#put" do
      it "updates instance with incoming representation" do
        @band.name   = "Strung Out"
        @band.label  = "Fat Wreck"
        @band.put("http://roar.example.com/bands/strungout", "application/xml")
        assert_equal "STRUNG OUT", @band.name
        assert_equal "FAT WRECK", @band.label
      end
    end
    
    describe "#patch" do
      it 'does something' do
        @band.label  = 'Fat Mike'
        @band.patch("http://roar.example.com/bands/strungout", "application/xml")
        assert_equal 'FAT MIKE', @band.label
      end
    end

    describe "#delete" do
      it 'does something' do
        @band.delete("http://roar.example.com/bands/metallica", "application/xml")
      end
    end

    # HEAD, OPTIONs?

  end
end
