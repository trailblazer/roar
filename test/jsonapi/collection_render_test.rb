require "test_helper"
require "roar/json/json_api"
require "json"
require "jsonapi/representer"

class JsonapiCollectionRenderTest < MiniTest::Spec
  it do
    article = Article.new(1, "Health walk", Author.new(2), Author.new("editor:1"), [Comment.new("comment:1", "Ice and Snow"),Comment.new("comment:2", "Red Stripe Skank")])
    article2 = Article.new(2, "Virgin Ska", Author.new("author:1"), nil, [Comment.new("comment:3", "Cool song!")])

    pp hash = ArticleDecorator.for_collection.new([article, article2]).to_hash

    hash.must_equal(
      {:data=>
        [{:type=>"articles",
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
               [{:type=>"comments",
                 :id=>"comment:1",
                 :attributes=>{"body"=>"Ice and Snow"}},
                {:type=>"comments",
                 :id=>"comment:2",
                 :attributes=>{"body"=>"Red Stripe Skank"}}],
              :links=>{"self"=>"http://comments/comment:2"}}},
          :links=>{"self"=>"http://Article/1"}},
         {:type=>"articles",
          :id=>"2",
          :attributes=>{"title"=>"Virgin Ska"},
          :relationships=>
           {"author"=>
             {:data=>{:type=>"authors", :id=>"author:1"},
              :links=>{"self"=>"http://authors/author:1"}},
            "comments"=>
             {:data=>
               [{:type=>"comments",
                 :id=>"comment:3",
                 :attributes=>{"body"=>"Cool song!"}}],
              :links=>{"self"=>"http://comments/comment:3"}}},
          :links=>{"self"=>"http://Article/2"}}],
       :links=>{"self"=>"//articles"},
       :included=>
        [{:type=>"authors", :id=>"2", :links=>{"self"=>"http://authors/2"}},
         {:type=>"editors",
          :id=>"editor:1",
          :links=>{"self"=>"http://authors/editor:1"}},
         {:type=>"comments",
          :id=>"comment:1",
          :attributes=>{"body"=>"Ice and Snow"},
          :links=>{"self"=>"http://comments/comment:1"}},
         {:type=>"comments",
          :id=>"comment:2",
          :attributes=>{"body"=>"Red Stripe Skank"},
          :links=>{"self"=>"http://comments/comment:2"}},
         {:type=>"authors",
          :id=>"author:1",
          :links=>{"self"=>"http://authors/author:1"}},
         {:type=>"comments",
          :id=>"comment:3",
          :attributes=>{"body"=>"Cool song!"},
          :links=>{"self"=>"http://comments/comment:3"}}]}
      )
  end

  describe "Fetching Resources (empty collection)" do
    let(:document) {
      {
        "data" => [],
        "links" => {
          "self" => "//articles"
        },
      }
    }

    let(:articles) { [] }
    subject { ArticleDecorator.for_collection.new(articles).to_json }

    it { subject.must_equal document.to_json }
  end

  describe "Collection Resources With Options" do
    class CollectionResourceObjectDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :articles

      property :id
      property :title
      property :author
    end

    let(:document) {
      {
        "data" => [
          {
            "type" => "articles",
            "id" => "1",
            "attributes" => {
              "title" => "My Article"
            }
          },
          {
            "type" => "articles",
            "id" => "2",
            "attributes" => {
              "title" => "My Other Article"
            }
          }
        ]
      }
    }

    subject do
      CollectionResourceObjectDecorator.for_collection.new([
        Article.new(1, 'My Article', 'Some Author'),
        Article.new(2, 'My Other Article', 'Some Author')
      ]).to_json(include: [:title, :id])
    end
    it { subject.must_equal document.to_json }
  end
end
