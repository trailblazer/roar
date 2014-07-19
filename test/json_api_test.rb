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


  module Singular
    include Representable::Hash
    include Roar::Representer::JSON # activates prepare_links
    include Roar::Representer::Feature::Hypermedia
    extend Roar::Representer::JSON::JsonApi::ClassMethods
    include Roar::Representer::JSON::JsonApi::Singular
    #include Roar::Representer::JSON::JsonApi::Document

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

    # self.representation_wrap = :songs

    link "songs.album" do
      {
        type: "album",
        href: "http://example.com/albums/{songs.album}"
      }
    end
   end

  describe "singular" do
    subject { song.extend(Singular).extend(Roar::Representer::JSON::JsonApi::Document) }

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
  # describe "minimal collection" do
  #   representer!([Representable::Hash]) do
  #     include Representable::Hash::Collection

  #     items extend: Singular

  #     # self.representation_wrap = :songs
  #   end

  #   subject { [song, song].extend(rpr).extend(Roar::Representer::JSON::JsonApi::Document) }

  #   # to_json
  #   it do
  #     subject.to_hash.must_equal(
  #       {
  #         "songs" => [
  #           {
  #             "id" => "1",
  #             "title" => "Computadores Fazem Arte",
  #             "links" => {
  #               "album" => "9",
  #               "musicians" => [ "1", "2" ]
  #             }
  #           }, {
  #             "id" => "1",
  #             "title" => "Computadores Fazem Arte",
  #             "links" => {
  #               "album" => "9",
  #               "musicians" => [ "1", "2" ]
  #             }
  #           }
  #         ]
  #       }
  #     )
  #   end
  # end


  # collection with links
  describe "collection with links" do
    representer!([Representable::Hash]) do
      include Representable::Hash::Collection

      items extend: Singular
        # link :musicians

      self.representable_attrs[:definitions][:links] = Singular.representable_attrs.get(:links)
      self.representable_attrs[:links] = Singular.representable_attrs[:links]

      include Roar::Representer::JSON::JsonApi::Document
      include Roar::Representer::Feature::Hypermedia # to implement #prepare_links!
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