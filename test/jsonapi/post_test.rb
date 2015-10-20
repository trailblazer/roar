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

    link :self do
      "http://api/articles/#{id}"
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

  describe "Parse" do
    let(:post_article) {
      {
        "data": {
          "type": "articles",
          "attributes": {
            "title": "Ember Hamster",
          },
          # that does do `photo.photographer= Photographer.find(9)`
          "relationships": {
            "author": {
              "data": { "type": "people", "id": "9", "name": "Celsito" } # FIXME: what should happen if i add `"name": "Celsito"` here? should that be read or not?
            },
            "comments": {
              "data": [
                { "type": "comment", "id": "2" },
                { "type": "comment", "id": "3" },
              ]
            }

          }
        }
      }
    }

    subject { CrudArticleCreateDecorator.new(Article.new(nil, nil, nil, [])).from_json(post_article.to_json) }

    it { subject.title.must_equal "Ember Hamster"  }
    it do
      subject.author.id.must_equal "9"
      subject.author.email.must_equal "9@nine.to"
      # subject.author.name.must_equal nil

      subject.comments.must_equal [Comment.new("2"), Comment.new("3")]
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