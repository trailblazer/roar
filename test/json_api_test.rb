require 'test_helper'
require 'roar/json/json_api'

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


  module Singular
    include Representable::Hash
    include Roar::JSON::JsonApi::Singular
    include Roar::JSON::JsonApi::Resource
    include Roar::JSON::JsonApi
    include(Roar::JSON::JsonApi::Document)

    property :id
    property :title

      # this will be abstracted once i understand the requirements.
    nested :_links do
      property :album_id, :as => :album
      collection :musician_ids, :as => :musicians
    end
    # has_one :album
    # has_many :musicians

    # self.representation_wrap = :songs

    link "songs.album" do
      {
        type: "album",
        href: "http://example.com/albums/{songs.album}"
      }
    end
   end

  describe "singular" do
    subject { song.extend(Singular) }

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

    # from_json
    it do
      song = OpenStruct.new.extend(Singular)
      song.from_hash(
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

      song.id.must_equal "1"
      song.title.must_equal "Computadores Fazem Arte"

    end
  end


  # collection with links
  describe "collection with links" do
    subject { [song, song].extend(Singular.for_collection) }

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
              "type" => "album" # DISCUSS: does that have to be albums ?
            },
          },
        }
      )
    end
  end


  describe "#from_json" do
    subject { [].extend(rpr).from_json [song].extend(rpr).to_json }

    # What should the object look like after parsing?
  end
end