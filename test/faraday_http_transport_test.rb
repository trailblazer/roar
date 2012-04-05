require 'test_helper'
require 'roar/representer/transport/faraday'

class FaradayHttpTransportTest < MiniTest::Spec
  describe 'FaradayHttpTransport' do
    before do
      @transport = Roar::Representer::Transport::Faraday.new
    end

    it "#get_uri returns response" do
      assert_equal "<method>get</method>",  @transport.get_uri("http://roar.example.com/method", "application/xml").body
    end

    it "#post_uri returns response" do
      assert_equal "<method>post</method>",  @transport.post_uri("http://roar.example.com/method", "booty", "application/xml").body
    end

    it "#put_uri returns response" do
      assert_equal "<method>put</method>",  @transport.put_uri("http://roar.example.com/method", "booty", "application/xml").body
    end

    it "#delete_uri returns response" do
      assert_equal "<method>delete</method>",  @transport.delete_uri("http://roar.example.com/method", "application/xml").body
    end

    it "#patch_uri returns response" do
      assert_equal "<method>patch</method>",  @transport.patch_uri("http://roar.example.com/method", "booty", "application/xml").body
    end

    describe 'non-existent resource' do
      before do
        @not_found_url = 'http://roar.example.com/missing-resource'
      end

      it '#get_uri raises a ResourceNotFound error' do
        assert_raises(Faraday::Error::ResourceNotFound) do
          @transport.get_uri(@not_found_url, "application/xml").body
        end
      end

      it '#post_uri raises a ResourceNotFound error' do
        assert_raises(Faraday::Error::ResourceNotFound) do
          @transport.post_uri(@not_found_url, 'crisis', "application/xml").body
        end
      end

      it '#post_uri raises a ResourceNotFound error' do
        assert_raises(Faraday::Error::ResourceNotFound) do
          @transport.post_uri(@not_found_url, 'crisis', "application/xml").body
        end
      end

      it '#delete_uri raises a ResourceNotFound error' do
        assert_raises(Faraday::Error::ResourceNotFound) do
          @transport.delete_uri(@not_found_url, "application/xml").body
        end
      end
    end

    describe 'server errors (500 Internal Server Error)' do
      it '#get_uri raises a ClientError' do
        assert_raises(Faraday::Error::ClientError) do
          @transport.get_uri('http://roar.example.com/deliberate-error', "application/xml").body
        end
      end
    end

  end
end
