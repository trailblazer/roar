require "test_helper"
require "roar/json/json_api"
require "json"
require "jsonapi/representer"

class JSONAPIFieldsetsTest < Minitest::Spec
  Article = Struct.new(:id, :title, :summary, :comments, :author)
  Comment = Struct.new(:id, :body, :good)
  Author = Struct.new(:id, :name, :email)

  let (:comments) { [Comment.new("c:1", "Cool!", true), Comment.new("c:2", "Nah", false)] }

  describe "Single Resource Object With Options" do
    class DocumentSingleResourceObjectDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :articles

      property :id
      property :title
      property :summary

      has_many :comments do
        type :comments

        property :id
        property :body
        property :good
      end

      has_one :author do
        type :author

        property :id
        property :name
        property :email
      end
    end

    let (:article) { Article.new(1, "My Article", "An interesting read.", comments, Author.new("a:1", "Celso", "celsito@trb.to")) }

    it "includes scalars" do
      DocumentSingleResourceObjectDecorator.new(article).
        to_json(include: [:title]).
        must_equal( {
          "data" => {
            "type" => "articles",
            "id" => "1",
            "attributes" => {
              "title" => "My Article"
            }
          }
        }.to_json )
    end

    it "includes compound objects" do
      DocumentSingleResourceObjectDecorator.new(article).
        to_hash(
          include:  [:id, :title, :included],
          included: {include: [:comments]}).
        must_equal Hash[{
          :data=>
            {:type=>"articles",
             :id=>"1",
             :attributes=>{"title"=>"My Article"},
            },
           :included=>
            [{:type=>"comments",
              :id=>"c:1",
              :attributes=>{"body"=>"Cool!", "good"=>true}},
             {:type=>"comments",
              :id=>"c:2",
              :attributes=>{"body"=>"Nah", "good"=>false}}
            ]
        }]
        # must_equal document.to_json
    end

    it "includes other compound objects" do
      DocumentSingleResourceObjectDecorator.new(article).
        to_hash(
          include:  [:title, :included],
          included: {include: [:author]}).
        must_equal Hash[{
          :data=>
            {:type=>"articles",
             :id=>"1",
             :attributes=>{"title"=>"My Article"},
            },
           :included=>
            [{:type=>"author", :id=>"a:1", :attributes=>{"name"=>"Celso", "email"=>"celsito@trb.to"}}]
        }]
        # must_equal document.to_json
    end

    describe "collection" do
      it "supports :includes" do
        DocumentSingleResourceObjectDecorator.for_collection.new([article]).
          to_hash(
            include:  [:title, :included],
            included: {include: [:author]}).
          must_equal Hash[{
            :data=>[
              {:type=>"articles",
               :id=>"1",
               :attributes=>{"title"=>"My Article"},
              }],
            :included=>
              [{:type=>"author", :id=>"a:1", :attributes=>{"name"=>"Celso", "email"=>"celsito@trb.to"}}]
          }]
      end

      # include: ROAR API
      it "blaaaaaaa" do
        DocumentSingleResourceObjectDecorator.for_collection.new([article]).
          to_hash(
            include:  [:title, :author],
            fields: {author: [:email]}
          ).
          must_equal Hash[{
            :data=>[
              {:type=>"articles",
               :id=>"1",
               :attributes=>{"title"=>"My Article"},
              }],
            :included=>
              [{:type=>"author", :id=>"a:1", :attributes=>{"email"=>"celsito@trb.to"}}]
          }]
      end
    end
  end

  describe "Collection Resources With Options" do
    class CollectionResourceObjectDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :articles

      property :id
      property :title
      property :summary
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

    it do
      CollectionResourceObjectDecorator.for_collection.new([
        Article.new(1, "My Article", "An interesting read."),
        Article.new(2, "My Other Article", "An interesting read.")
      ]).to_json(include: [:title, :id]).must_equal document.to_json
    end
  end
end