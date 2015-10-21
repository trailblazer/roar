require 'test_helper'
require 'roar/json/json_api'
require 'json'

# this test is based on idea of http://jsonapi.org/format/1.0
# we don't wanna reinvent the wheel so we are using examples provided by the spec itself
class JSONAPITest < MiniTest::Spec
  Author = Struct.new(:id, :email, :name, :article) do
    def self.find_by(options)
      AuthorNine if options[:id].to_s=="9"
    end
  end
  AuthorNine = Author.new(9, "9@nine.to")

  Article = Struct.new(:id, :title, :comments, :author)

  Comment = Struct.new(:id, :author, :body)

  describe "Single Resource Object" do
    class DocumentSingleResourceObjectDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :articles

      property :id
      property :title
    end

    let(:document) {
      {
        "data": {
          "type": "articles",
          "id": "1",
          "attributes": {
            "title": "My Article"
          }
        }
      }
    }

    subject { DocumentSingleResourceObjectDecorator.new(Article.new(1, 'My Article')).to_json }
    it { subject.must_equal document.to_json }
  end

  class ArticleDecorator < Roar::Decorator
    include Roar::JSON::JSONAPI
    type :articles

    href "http://api/articles"

    property :id
    property :title


    include Roar::JSON
    include Roar::Hypermedia
    link(:self) { "http://#{represented.class}/" }


    property :author, class: Author, type: 'people' do # relationship.
      include Roar::JSON
      include Roar::Hypermedia

      property :id

      link(:self)    { "http://api/articles/#{represented.id}/relationships/author" }
      link(:related) { "http://api/articles/#{represented.id}/author" }
    end

    # compound do
      property :author, type: "author", decorator: true do
        include Roar::JSON::JSONAPI
        include Roar::JSON
        include Roar::Hypermedia
        type :authors

        property :id
        property :email
        link(:self) { "http://comments/#{represented.id}" }
      end

      # collection :comments, type: "comments" do
      #   include Roar::JSON::JSONAPI
      #   include Roar::JSON
      #   include Roar::Hypermedia
      #   type :comments

      #   property :id
      #   property :body
      #   link(:self) { "http://comments/#{represented.id}" }

      #   property :author, type: "people" do # relationships in the compound entity.
      #     include Roar::JSON
      #     include Roar::Hypermedia


      #     property :id
      #     link(:self) { "http://author/#{represented.id}" } # optional
      #   end
      # end
    # end

  end


  describe "Resource Objects" do
    describe "Relationships" do
      let(:document) {
        {
          "data": {
            "type": "articles",
            "id": "1",
            "attributes": {
              "title": "My Article"
            },
            "relationships": {
              "author": {
                "data": {
                  "id": "9",
                  "type": "people"
                },
                "links": {
                  "self": "http://api/articles/1/relationships/author",
                  "related": "http://api/articles/1/author"
                }
              }
            },
            "links": {
              "self": "http://JSONAPITest::Article/",
            },
            "included": [
              {
                "type": "comments",
                "id":   1,
                "attributes": {
                  "body": "JSON 4 shizzl!"
                },
                "links": {
                  "self": "http://comments/1",
                }
              }
            ]
          }
        }
      }

      let(:article) { Article.new(1, "My Article", [Comment.new(1, Author.new(9), "JSON 4 shizzl!")], Author.new(9)) }
      subject { ArticleDecorator.new(article).to_json }
      it { subject.must_equal document.to_json }
    end
  end

  describe "Fetching Data" do
    describe "Fetching Resources" do
      let(:document) {
        {
          "links": {
            "self": "http://api/articles"
          },
          "data": [{
            "type": "articles",
            "id": "1",
            "attributes": {
              "title": "JSON API paints my bikeshed!"
            }
          }, {
            "type": "articles",
            "id": "2",
            "attributes": {
              "title": "Rails is Omakase"
            }
          }]
        }
      }

      let(:articles) {
        [ Article.new(1, "JSON API paints my bikeshed!"), Article.new(2, "Rails is Omakase") ]
      }
      subject { ArticleDecorator.for_collection.new(articles).to_json }
      it { subject.must_equal document.to_json }
    end

    describe "Fetching Resources (empty collection)" do
      let(:document) {
        {
          "links": {
            "self": "http://api/articles"
          },
          "data": []
        }
      }

      let(:articles) {
        []
      }
      subject { ArticleDecorator.for_collection.new(articles).to_json }
      it { subject.must_equal document.to_json }
    end
  end
end
