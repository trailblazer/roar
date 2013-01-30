require 'test_helper'
require 'roar/representer/json/collection_json'

class CollectionJsonTest < MiniTest::Spec
  subject { Object.new().extend(rpr)  }
  let(:song) { OpenStruct.new(:title => "scarifice", :length => 43) }

  representer_for([Roar::Representer::JSON::CollectionJSON]) do
    version "1.0"
    href { "//songs/" }

    link(:feed) { "//songs/feed" }

    items do
      href { "//songs/scarifice" }

      property :title, :prompt => "Song title"
      property :length, :prompt => "Song length"

      link(:download) { "//songs/scarifice.mp3" }
      link(:stats) { "//songs/scarifice/stats" }
    end

    template do
      property :title, :prompt => "Song title"
      property :length, :prompt => "Song length"
    end

    queries do
      link :search do
        {:href => "//search", :data => [{:name => "q", :value => ""}]}
      end
    end
  end

  describe "#to_json" do
    it "renders document" do
      [song].extend(rpr).to_hash.must_equal(
      {
        :collection=>{
          "version"=>"1.0",
          "href"=>"//songs/",

          "template"=>{
            :data=>[
              {:name=>"title", :value=>nil},
              {:name=>"length", :value=>nil}
            ]
          },

          "queries"=>[
            {:rel=>:search, :href=>"//search", 
              :data=>[
                {:name=>"q", :value=>""}
              ]
            }
          ],

          "items"=>[
            {
              "links"=>[
                {:rel=>:download, :href=>"//songs/scarifice.mp3"},
                {:rel=>:stats, :href=>"//songs/scarifice/stats"}
              ],
              "href"=>"//songs/scarifice",
              :data=>[
                {:name=>"title", :value=>"scarifice"},
                {:name=>"length", :value=>43}
              ]
            }
          ],

          "links"=>[
            {:rel=>:feed, :href=>"//songs/feed"}
          ]
        }
      })# %{{"collection":{"version":"1.0","href":"//songs/","items":[{"href":"//songs/scarifice","links":[{"rel":"download","href":"//songs/scarifice.mp3"},{"rel":"stats","href":"//songs/scarifice/stats"}],"data":[{"name":"title","value":"scarifice"},{"name":"length","value":43}]}],"template":{"data":[{"name":"title","value":null},{"name":"length","value":null}]},"queries":[{"rel":"search","href":"//search","data":[{"name":"q","value":""}]}],"links":[{"rel":"feed","href":"//songs/feed"}]}}}
    end
  end
end