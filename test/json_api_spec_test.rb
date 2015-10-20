require 'test_helper'
require 'roar/json/json_api'
require 'json'

# this test is based on idea of http://jsonapi.org/format/1.0
# we don't wanna reinvent the wheel so we are using examples provided by the spec itself
class JSONAPITest < MiniTest::Spec
  Author = Struct.new(:id) do
    attr_reader :article_id
    def article=(article)
      @article_id = article.id
    end
  end
  Article = Struct.new(:id, :title) do
    attr_reader :author
    def author=(author)
      @author = author
      @author.article = self
    end
  end
  class ArticleDecorator < Roar::Decorator
    include Roar::JSON::JSONAPI
    type :articles

    href "http://api/articles"

    property :id
    property :title

    link :self do
      "http://api/articles/#{id}"
    end

    property :author, class: Author, type: 'people' do
      include Roar::JSON
      include Roar::Hypermedia

      property :id

      # TODO: support links on relationships
      link :self do
        "http://api/articles/#{represented.article_id}/relationships/author"
      end

      link :related do
        "http://api/articles/#{represented.article_id}/author"
      end
    end
  end

  describe "Document Structure" do
    describe "Single Resource Object" do
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
      class DocumentSingleResourceObjectDecorator < Roar::Decorator
        include Roar::JSON::JSONAPI
        type :articles

        property :id
        property :title
      end

      subject { DocumentSingleResourceObjectDecorator.new(Article.new(1, 'My Article')).to_json }
      it { subject.must_equal document.to_json }
    end

    describe "Resource Identifier Object" do
      let(:document) {
        {
          "data": {
            "type": "articles",
            "id": "1"
          }
        }
      }
      class DocumentSingleResourceObjectDecorator < Roar::Decorator
        include Roar::JSON::JSONAPI
        type :articles

        property :id
        property :title
      end

      subject { DocumentSingleResourceObjectDecorator.new(OpenStruct.new(id: 1)).to_json }
      it { subject.must_equal document.to_json }
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
                "self": "http://api/articles/1",
              }
            }
          }
        }

        let(:article) {
          Article.new(1, "My Article").send("author=", Author.new(9))
        }
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

  describe "CRUD" do
    Photographer = Struct.new(:id) do
      attr_reader :photo_id
      def photo=(photo)
        @photo_id = photo.id
      end
    end
    Photo = Struct.new(:id, :title, :src) do
      attr_reader :photographer
      def photographer=(photographer)
        @photographer = photographer
        @photographer.photo = self
      end
    end

    class CrudPhotoCreateDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :photos

      property :id
      property :title
      property :src

      link :self do
        "http://api/photos/#{id}"
      end

      property :photographer, class: Photographer, type: 'people' do
        include Roar::JSON
        include Roar::Hypermedia

        property :id
      end
    end

    describe "Create" do
      describe "Parse" do
        let(:post_photos) {
          {
            "data": {
              "type": "photos",
              "attributes": {
                "title": "Ember Hamster",
                "src": "http://example.com/images/productivity.png"
              },
              # does that do `photo.photographer= Photographer.find(9)` ?
              "relationships": {
                "photographer": {
                  "data": { "type": "people", "id": "9" }
                }
              }
            }
          }
        }

        subject { CrudPhotoCreateDecorator.new(Photo.new).from_json(post_photos.to_json) }

        it { subject.title.must_equal "Ember Hamster"  }
        it { subject.src.must_equal "http://example.com/images/productivity.png"  }
        it { subject.photographer.id.must_equal 9 }
      end

      describe "Render" do
        let(:rendered_post_photos) {
          {
            "data": {
              "type": "photos",
              "id": "2",
              "attributes": {
                "title": "Ember Hamster",
                "src": "http://example.com/images/productivity.png"
              },
              "relationships": {
                "photographer": {
                  "data": {
                    # TODO: support type on relationships
                    "id": "9",
                    "type": "people"
                  }
                }
              },
              "links": {
                "self": "http://api/photos/2"
              }
            }
          }
        }

        let(:photo) {
          Photo.new(2, "Ember Hamster", "http://example.com/images/productivity.png").send("photographer=", Photographer.new(9))
        }
        subject { CrudPhotoCreateDecorator.new(photo).to_json }
        it { subject.must_equal rendered_post_photos.to_json }
      end
    end
  end
end
