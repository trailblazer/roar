require "test_helper"
require "roar/json/json_api"
require "json"
require "jsonapi/representer"

class JsonapiRenderTest < MiniTest::Spec
  it do
    article = Article.new(1, "Health walk", Author.new(2), Author.new("editor:1"), [Comment.new("comment:1", "Ice and Snow"),Comment.new("comment:2", "Red Stripe Skank")])

    pp hash = ArticleDecorator.new(article).to_hash

    hash.must_equal( {
          :data=>
            {
              :type=>"articles",
               :id=>"1",
               :attributes=>{"title"=>"Health walk"},
               :relationships=>
                {"author"=>
                  {:data=>{:type=>"authors", :id=>"2"},
                   :links=>{"self"=>"http://authors/2"}},
                 "editor"=>
                  {:data=>{:type=>"editors", :id=>"editor:1"},
                   :links=>{"self"=>"http://authors/editor:1"}},
                 "comments"=>
                  {:data=>
                    [
                      {
                        :type=>"comments",
                        :id=>"comment:1",
                        :attributes=>{"body"=>"Ice and Snow"}
                      },
                      {
                        :type=>"comments",
                        :id=>"comment:2",
                        :attributes=>{"body"=>"Red Stripe Skank"}
                      }
                    ], # FIXME.
                   :links=>{"self"=>"http://comments/comment:2"}}}, # FIXME: this only works when a relationship is present.
               :links=>{"self"=>"http://Article/1"},
              :included=>
                [
                  {
                    :type=>"authors",
                    :id=>"2",
                    :links=>{"self"=>"http://authors/2"}
                  },
                  {
                    :type=>"editors",
                    :id=>"editor:1",
                    :links=>{"self"=>"http://authors/editor:1"}
                  },
                  {
                    :type=>"comments",
                    :id=>"comment:1",
                    :attributes=>{"body"=>"Ice and Snow"},
                    :links=>{"self"=>"http://comments/comment:1"}
                  },
                  {
                    :type=>"comments",
                    :id=>"comment:2",
                    :attributes=>{"body"=>"Red Stripe Skank"},
                    :links=>{"self"=>"http://comments/comment:2"}
                    },
                ]
           }
        })
  end

  describe "Single Resource Object" do
    class DocumentSingleResourceObjectDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :articles

      property :id
      property :title
    end

    let(:document) {
      {
        "data" => {
          "type" => "articles",
          "id" => "1",
          "attributes" => {
            "title" => "My Article"
          }
        }
      }
    }

    subject { DocumentSingleResourceObjectDecorator.new(Article.new(1, 'My Article')).to_json }
    it { subject.must_equal document.to_json }
  end
end