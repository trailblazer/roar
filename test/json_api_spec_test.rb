require 'test_helper'
require 'roar/json/json_api'
require 'json'

# this test is based on idea of http://jsonapi.org/format/1.0
# we don't wanna reinvent the wheel so we are using examples provided by the spec itself
require "representable/version"
if Gem::Version.new(Representable::VERSION) >= Gem::Version.new("2.1.4") # TODO: remove check once we bump representable dependency.
  class JSONAPITest < MiniTest::Spec
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
        
        subject { DocumentSingleResourceObjectDecorator.new(OpenStruct.new(id: 1, title: 'My Article')).to_json }
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
                "links": {
                  "self": "http://api/articles/1",
                  "related": "http://api/articles/1/author"
                },
                "relationships": {
                  "author": {
                    "links": {
                      "self": "http://api/articles/1/relationships/author",
                      "related": "http://api/articles/1/author"
                    },
                    "data": { "type": "people", "id": "9" }
                  }
                }
              }
            }
          }
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
          class ArticleRelationshipDecorator < Roar::Decorator
            include Roar::JSON::JSONAPI
            type :articles

            property :id
            property :title
        
            link :self do
              "http://api/articles/#{id}"
            end
            
            property :author, class: Author do
              # type :people

              property :id
              
              # link :self do
              #   "http://api/author/#{id}"
              # end
              #
              # link :related do
              #   "http://api/author/#{article_id}/author"
              # end
            end
          end
          
          let(:article) {
            Article.new(1, "My Article").send("author=", Author.new(9))
          }
          subject { ArticleRelationshipDecorator.new(article).to_json }
          # it { subject.must_equal document.to_json }
        end
      end
    end

    describe "CRUD" do
      class CrudPhotoCreateDecorator < Roar::Decorator
        include Roar::JSON::JSONAPI
        type :photos

        property :id
        property :title
        property :src
        
        link :self do
          "http://api/photos/#{id}"
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
                "relationships": {
                  "photographer": {
                    "data": { "type": "people", "id": "9" }
                  }
                }
              }
            }
          }

          subject { CrudPhotoCreateDecorator.new(OpenStruct.new).from_json(post_photos.to_json) }

          it { subject.title.must_equal "Ember Hamster"  }
          it { subject.src.must_equal "http://example.com/images/productivity.png"  }
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
                "links": {
                  "self": "http://api/photos/2"
                }
                # },
                # "relationships": {
                #   "photographer": {
                #     "data": { "type": "people", "id": "9" }
                #   }
                # }
              }
            }
          }

          subject { CrudPhotoCreateDecorator.new(OpenStruct.new(id: 2, title: 'Ember Hamster', src: 'http://example.com/images/productivity.png')).to_json }
          it { subject.must_equal rendered_post_photos.to_json }
        end
      end
    end
  end
end
