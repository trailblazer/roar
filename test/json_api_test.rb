require 'test_helper'
require 'roar/representer/json/json_api'

class JsonApiTest < MiniTest::Spec
  let(:song) { OpenStruct.new(
                          title: 'Computadores Fazem Arte',
                          album: OpenStruct.new(id: 1, title: 'Da Lama ao Caos'),
                          musicians: [OpenStruct.new(id: 1, name: 'Chico Science'), 
                                      OpenStruct.new(id: 2, name: 'Jorge Du Peixe')] 
                        ) }

  representer!([Roar::Representer::JSON::JsonApi]) do
    property :id
    property :title

    link "songs.album" do
      {
        type: "album",
        href: "http://example.com/albums/{songs.album}"
      }
    end
    # link "songs.musicians", type: :musicians do
    #   "http://example.com/musicians/{songs.musicians}"
    # end
  end

  subject { song.extend(rpr) }

  describe "#to_json" do
    it "renders document" do
      subject.to_json.must_equal(
          %{{
            "links": {
              "songs.album": {
                "href": "http://example.com/albums/{songs.album}",
                "type": "albums"
              },
              "songs.musicians": {
                "href": "http://example.com/musicians/{songs.musicians}",
                "type": "musicians"
              }
            },
            "songs": [{
              "id": "1",
              "title": "Computadores Fazem Arte",
              "links": {
                "album": "9",
                "musicians": [ "1", "2" ]
              }
            }]
          }}
        )
    end

    context "including representations of linked resources" do
      before do
        rpr.class_eval do
          include_linked
        end
      end

      it "renders document" do
        subject.to_json.must_equal(
            %{{
              "links": {
                "songs.album": {
                  "href": "http://example.com/albums/{songs.album}",
                  "type": "albums"
                },
                "songs.musicians": {
                  "href": "http://example.com/musicians/{songs.musicians}",
                  "type": "musicians"
                }
              },
              "songs": [{
                "id": "1",
                "title": "Computadores Fazem Arte",
                "links": {
                  "album": "9",
                  "musicians": [ "1", "2" ]
                }
              }],
              "linked": {
                "albums": [{
                  "id": "9",
                  "href": "http://example.com/albums/9",
                  "title": "Da Lama ao Caos"
                }],
                "musicians": [{
                  "id": "1",
                  "href": "http://example.com/musicians/1",
                  "name": "Chico Science"
                }, {
                  "id": "2",
                  "href": "http://example.com/musicians/2",
                  "name": "Jorge Du Peixe"
                }]
              }
            }}
          )
      end
    end
  end

  describe "#from_json" do
    subject { [].extend(rpr).from_json [song].extend(rpr).to_json }

    # What should the object look like after parsing?
  end
end