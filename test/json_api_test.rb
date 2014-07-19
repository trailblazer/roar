require 'test_helper'
require 'roar/representer/json/json_api'

class JsonApiTest < MiniTest::Spec
  let(:song) { s = OpenStruct.new(
    id: "1",
    title: 'Computadores Fazem Arte',
    album: OpenStruct.new(id: 9),
    :album_id => "9",
    :musician_ids => ["1","2"],
    musicians: [OpenStruct.new(id: 1), OpenStruct.new(id: 2)]
  )

   }

  describe "singular" do
    representer!([Roar::Representer::JSON::JsonApi]) do
      # property :songs, getter: lambda { |*| self }, use_decorator: true do
        property :id
        property :title

        # this will be abstracted once i understand the requirements.
        nested :_links do
          property :album_id, :as => :album
          collection :musician_ids, :as => :musicians
        end
      # end
      # has_one :album
      # has_many :musicians

      self.representation_wrap = :songs

      link "songs.album" do
        {
          type: "album",
          href: "http://example.com/albums/{songs.album}"
        }
      end
      # link :musicians
    end

    subject { song.extend(rpr) }

    # to_json
    it do
      subject.to_hash.must_equal(
        {
          "songs" => {
            "id" => "1",
            "title" => "Computadores Fazem Arte",
            "links" => {
              "album" => "9",
              "musicians" => [ "1", "2" ]
            }
          },
          "links" => {
            "songs.album"=> {
              "href"=>"http://example.com/albums/{songs.album}", "type"=>"album"
            }
          }
        }
      )
    end
  end


  # collection
  describe "minimal collection" do
    representer!([Representable::Hash]) do
      include Representable::Hash::Collection

      items( {}) do
        property :id
        property :title

        # this will be abstracted once i understand the requirements.
        nested :links do
          property :album_id, :as => :album
          collection :musician_ids, :as => :musicians
        end
      end

      self.representation_wrap = :songs
    end

    subject { [song, song].extend(rpr) }

    # to_json
    it do
      subject.to_hash.must_equal(
        {
          "songs" => [
            {
              "id" => "1",
              "title" => "Computadores Fazem Arte",
              "links" => {
                "album" => "9",
                "musicians" => [ "1", "2" ]
              }
            }, {
              "id" => "1",
              "title" => "Computadores Fazem Arte",
              "links" => {
                "album" => "9",
                "musicians" => [ "1", "2" ]
              }
            }
          ]
        }
      )
    end
  end


  # collection with links
  describe "collection with links" do
    representer!([Representable::Hash]) do
      include Representable::Hash::Collection

      items({}) do
        property :id
        property :title

        # this will be abstracted once i understand the requirements.
        nested :private_links do
          property :album_id, :as => :album
          collection :musician_ids, :as => :musicians
        end

        include Roar::Representer::JSON::JsonApi

        link "songs.album" do
          {
            type: "album",
            href: "http://example.com/albums/{songs.album}"
          }
        end
        # link :musicians
      end

      self.representation_wrap = :songs
    end

    subject { [song, song].extend(rpr) }

    # to_json
    it do
      subject.to_hash.must_equal(
        {
          "songs" => [
            {
              "id" => "1",
              "title" => "Computadores Fazem Arte",
              "links" => {
                "album" => "9",
                "musicians" => [ "1", "2" ]
              }
            }, {
              "id" => "1",
              "title" => "Computadores Fazem Arte",
              "links" => {
                "album" => "9",
                "musicians" => [ "1", "2" ]
              }
            }
          ],
          "links" => {
            "songs.album" => {
              "href" => "http://example.com/albums/{songs.album}",
              "type" => "albums"
            },
          },
        }
      )
    end
  end

     # %{{
            #   "links": {
            #     "songs.album": {
            #       "href": "http://example.com/albums/{songs.album}",
            #       "type": "albums"
            #     },
            #     "songs.musicians": {
            #       "href": "http://example.com/musicians/{songs.musicians}",
            #       "type": "musicians"
            #     }
            #   },
            #   "songs": [{
            #     "id": "1",
            #     "title": "Computadores Fazem Arte",
            #     "links": {
            #       "album": "9",
            #       "musicians": [ "1", "2" ]
            #     }
            #   }]
            # }}


  describe "#from_json" do
    subject { [].extend(rpr).from_json [song].extend(rpr).to_json }

    # What should the object look like after parsing?
  end
end