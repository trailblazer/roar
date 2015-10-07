require 'test_helper'
require 'roar/json/hal'

class HalJsonTest < MiniTest::Spec
  let(:rpr) do
    Module.new do
      include Roar::JSON
      include Roar::JSON::HAL

      links :self do
        [{:lang => "en", :href => "http://en.hit"},
         {:lang => "de", :href => "http://de.hit"}]
      end

      link :next do
        "http://next"
      end
    end
  end

  subject { Object.new.extend(rpr) }

  describe "links" do
    describe "parsing" do
      it "parses link array" do # TODO: remove me.
        obj = subject.from_json("{\"_links\":{\"self\":[{\"lang\":\"en\",\"href\":\"http://en.hit\"},{\"lang\":\"de\",\"href\":\"http://de.hit\"}]}}")
        obj.links.must_equal "self" => [link("rel" => "self", "href" => "http://en.hit", "lang" => "en"), link("rel" => "self", "href" => "http://de.hit", "lang" => "de")]
      end

      it "parses single links" do # TODO: remove me.
        obj = subject.from_json("{\"_links\":{\"next\":{\"href\":\"http://next\"}}}")
        obj.links.must_equal "next" => link("rel" => "next", "href" => "http://next")
      end

      it "parses link and link array" do
        obj = subject.from_json(%@{"_links":{"next":{"href":"http://next"}, "self":[{"lang":"en","href":"http://en.hit"},{"lang":"de","href":"http://de.hit"}]}}@)
        obj._links.must_equal "next"=>link("rel" => "next", "href" => "http://next"), "self"=>[link("rel" => "self", "href" => "http://en.hit", "lang" => "en"), link("rel" => "self", "href" => "http://de.hit", "lang" => "de")]
      end

      it "parses empty link array" do
        subject.from_json("{\"_links\":{\"self\":[]}}").links[:self].must_equal nil
      end

      it "parses non-existent link array" do
        subject.from_json("{\"_links\":{}}").links[:self].must_equal nil # DISCUSS: should this be []?
      end

      # it "rejects single links declared as array" do
      #   assert_raises TypeError do
      #     subject.from_json("{\"_links\":{\"self\":{\"href\":\"http://next\"}}}")
      #   end
      # end
    end

    describe "rendering" do
      it "renders link and link array" do
        subject.to_json.must_equal "{\"_links\":{\"self\":[{\"lang\":\"en\",\"href\":\"http://en.hit\"},{\"lang\":\"de\",\"href\":\"http://de.hit\"}],\"next\":{\"href\":\"http://next\"}}}"
      end
    end
  end

  describe "empty link array" do
    representer!([Roar::JSON::HAL]) do
      links(:self) { [] }
    end

    it "gets render" do
      Object.new.extend(representer).to_json.must_equal %@{"_links":{"self":[]}}@
    end
  end


  describe "_links and _embedded" do
    representer_for([Roar::JSON::HAL]) do
      property :id
      collection :songs, class: Song, embedded: true do
        include Roar::JSON::HAL

        property :title
        link(:self) { "http://songs/#{title}" }
      end

      link(:self) { "http://albums/#{id}" }
    end

    let(:album) { Album.new(:songs => [Song.new(:title => "Beer")], :id => 1).extend(representer) }

    it "render links and embedded resources according to HAL" do
      album.to_json.must_equal "{\"id\":1,\"_embedded\":{\"songs\":[{\"title\":\"Beer\",\"_links\":{\"self\":{\"href\":\"http://songs/Beer\"}}}]},\"_links\":{\"self\":{\"href\":\"http://albums/1\"}}}"
    end

    it "parses links and resources following the mighty HAL" do
      album.from_json("{\"id\":2,\"_embedded\":{\"songs\":[{\"title\":\"Coffee\",\"_links\":{\"self\":{\"href\":\"http://songs/Coffee\"}}}]},\"_links\":{\"self\":{\"href\":\"http://albums/2\"}}}")
      assert_equal 2, album.id
      assert_equal "Coffee", album.songs.first.title
      assert_equal "http://songs/Coffee", album.songs.first.links["self"].href
      assert_equal "http://albums/2", album.links["self"].href
    end

    it "doesn't require _links and _embedded to be present" do
      album.from_json("{\"id\":2}")
      assert_equal 2, album.id

      # in newer representables, this is not overwritten to an empty [] anymore.
      assert_equal ["Beer"], album.songs.map(&:title)
      album.links.must_equal nil
    end
  end

end

class JsonHalTest < MiniTest::Spec
  Album  = Struct.new(:artist, :songs)
  Artist = Struct.new(:name)
  Song = Struct.new(:title)

  def self.representer!
    super([Roar::JSON::HAL])
  end

  def representer
    rpr
  end

  describe "render_nil: false" do
    representer! do
      property :artist, embedded: true, render_nil: false do
        property :name
      end

      collection :songs, embedded: true, render_empty: false do
        property :title
      end
    end

    it { Album.new(Artist.new("Bare, Jr."), [Song.new("Tobacco Spit")]).extend(representer).to_hash.must_equal({"_embedded"=>{"artist"=>{"name"=>"Bare, Jr."}, "songs"=>[{"title"=>"Tobacco Spit"}]}}) }
    it { Album.new.extend(representer).to_hash.must_equal({}) }
  end

  describe "as: alias" do
    representer! do
      property :artist, as: :my_artist, class: Artist, embedded: true do
        property :name
      end

      collection :songs, as: :my_songs, class: Song, embedded: true do
        property :title
      end
    end

    it { Album.new(Artist.new("Bare, Jr."), [Song.new("Tobacco Spit")]).extend(representer).to_hash.must_equal({"_embedded"=>{"my_artist"=>{"name"=>"Bare, Jr."}, "my_songs"=>[{"title"=>"Tobacco Spit"}]}}) }
    it { Album.new.extend(representer).from_hash({"_embedded"=>{"my_artist"=>{"name"=>"Bare, Jr."}, "my_songs"=>[{"title"=>"Tobacco Spit"}]}}).inspect.must_equal "#<struct JsonHalTest::Album artist=#<struct JsonHalTest::Artist name=\"Bare, Jr.\">, songs=[#<struct JsonHalTest::Song title=\"Tobacco Spit\">]>" }
  end
end

class HalCurieTest < MiniTest::Spec
  representer!([Roar::JSON::HAL]) do
    link "doc:self" do
      "/"
    end

    curies do
      [{:name => :doc,
        :href => "//docs/{rel}",
        :templated => true}]
    end
  end

  it { Object.new.extend(rpr).to_hash.must_equal({"_links"=>{"doc:self"=>{"href"=>"/"}, "curies"=>[{"name"=>:doc, "href"=>"//docs/{rel}", "templated"=>true}]}}) }
end
