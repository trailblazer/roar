require "test_helper"
require "roar/json/json_api"
require "json"

class JsonapiPostTest < MiniTest::Spec
  Author = Struct.new(:id, :email, :name) do
    def self.find_by(options)
      AuthorNine if options[:id].to_s=="9"
    end
  end
  AuthorNine = Author.new(9, "9@nine.to")

  Article = Struct.new(:id, :title, :author, :comments)

  Comment = Struct.new(:id) do
    def self.find_by(options)
      new
    end
  end



  class CrudArticleCreateDecorator < Roar::Decorator
    include Roar::JSON::JSONAPI
    type :articles

    property :id
    property :title

    include Roar::JSON
    include Roar::Hypermedia
    link :self do
      "http://api/articles/#{represented.id}"
    end

include Representable::Debug
    property :author, class: Author, populator: ::Representable::FindOrInstantiate, type: "people" do
      include Roar::JSON
      include Roar::Hypermedia

      property :id
      property :name
    end

    collection :comments, class: Comment, populator: ::Representable::FindOrInstantiate do # FIXME: type?
      property :id
    end
  end



  describe "Render" do
    let(:rendered_post_photos) {
      {
        "data": {
          "type": "articles",
          "id": "2",
          "attributes": {
            "title": "Ember Hamster",
          },
          "relationships": {
            "author": {
              "data": {
                # TODO: support type on relationships
                "id": "9",
                "type": "people"
              }
            }
          },
          "links": {
            "self": "http://api/articles/2"
          }
        }
      }
    }

    let(:photo) {
      Article.new(2, "Ember Hamster").tap do |article|
        article.author= Author.new(9)
      end
    }
    subject { CrudArticleCreateDecorator.new(photo).to_json }
    it { subject.must_equal rendered_post_photos.to_json }
  end
end