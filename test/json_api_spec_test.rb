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
                "relationships": {
                  "author": {
                    # TODO: support links on relationships
                    "links": {
                      "self": "http://api/articles/1/relationships/author",
                      "related": "http://api/articles/1/author"
                    },
                    "data": { 
                      "id": "9",
                      "type": "people"
                    }
                  }
                },
                "links": {
                  "self": "http://api/articles/1",
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
            
            property :author, class: Author, type: 'people' do
              include Roar::JSON
              include Roar::Hypermedia

              property :id
              
              # TODO: support links on relationships
              link :self do
                "http://api/author/#{represented.id}"
              end

              link :related do
                "http://api/author/#{represented.article_id}/author"
              end
            end
          end
          
          let(:article) {
            Article.new(1, "My Article").send("author=", Author.new(9))
          }
          subject { ArticleRelationshipDecorator.new(article).to_json }
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
          property :id
          
          # TODO: support links on relationships
          # link :self do
          #   "http://api/author/#{id}"
          # end
          #
          # link :related do
          #   "http://api/author/#{article_id}/author"
          # end
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
end
