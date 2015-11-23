require "test_helper"
require "roar/json/json_api"
require "json"
require "jsonapi/representer"

class JSONAPIFieldsetsTest < Minitest::Spec
  Article = Struct.new(:id, :title, :summary)

  describe "Single Resource Object With Options" do
    class DocumentSingleResourceObjectDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :articles

      property :id
      property :title
      property :summary
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

    subject { DocumentSingleResourceObjectDecorator.new(Article.new(1, "My Article", "An interesting read.")).to_json(include: [:title, :id]) }
    it { subject.must_equal document.to_json }
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