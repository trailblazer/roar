require 'test_helper'
require 'roar/json/mason'
require 'roar/json/hal'
require 'pry'

class MasonJsonTest < MiniTest::Spec
  let(:rpr) do
    Module.new do
      include Roar::JSON
      include Roar::JSON::Mason

      link :self do
        {
          href: "http://post",
          method: "POST"
        }
      end

      link :next do
        "http://next"
      end
    end
  end

  subject { Object.new.extend(rpr) }

  describe "link" do
    describe "rendering" do
      it "renders link and link with params" do
        subject.to_json.must_equal "{\"@controls\":{\"self\":{\"href\":\"http://post\",\"method\":\"POST\"},\"next\":{\"href\":\"http://next\"}}}"
      end
    end
  end


  describe "@controls" do
    representer_for([Roar::JSON::Mason]) do
      property :id
      collection :songs, class: Song, embedded: true do
        include Roar::JSON::Mason

        property :title
        link(:self) { "http://songs/#{title}" }
      end

      link(:self) { "http://albums/#{id}" }
    end

    let(:album) { Album.new(:songs => [Song.new(:title => "Beer")], :id => 1).extend(representer) }

    it "render controls and embedded resources according to Mason" do
      album.to_json.must_equal "{\"id\":1,\"songs\":[{\"title\":\"Beer\",\"@controls\":{\"self\":{\"href\":\"http://songs/Beer\"}}}],\"@controls\":{\"self\":{\"href\":\"http://albums/1\"}}}"
    end
  end
end

class MasonCurieTest < MiniTest::Spec
  representer_for([Roar::JSON::Mason]) do
    collection :songs, class: Song, embedded: true do
      include Roar::JSON::Mason

      curies :inner do
        "inner"
      end
      link(:self) { "http://songs/#{title}" }
    end

    curies :top do
      "top"
    end

    link(:self) { "http://albums/#{id}" }
  end

  let(:album) { Album.new(:songs => [Song.new(:title => "Beer")], :id => 1).extend(representer) }

  it "collects curies at the top level" do
    album.to_hash["@namespaces"].must_equal({
        "top" => {"name" => "top"},
        "inner" => {"name" => "inner"}
      })
    album.to_hash["songs"][0]["@namespaces"].must_be_nil
  end
end
