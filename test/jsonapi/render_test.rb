require "test_helper"
require "roar/json/json_api"
require "json"

class JsonapiRenderTest < MiniTest::Spec
  Author = Struct.new(:id, :email, :name) do
    def self.find_by(options)
      AuthorNine if options[:id].to_s=="9"
    end
  end
  AuthorNine = Author.new(9, "9@nine.to")

  Article = Struct.new(:id, :title, :author, :editor, :comments)

  Comment = Struct.new(:id, :body) do
    def self.find_by(options)
      new
    end
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

    bla=nested :relationships do
      property :author, type: "author" do
        include Roar::JSON::JSONAPI
        include Roar::JSON
        include Roar::Hypermedia
        type :authors

        property :id
        property :email
        link(:self) { "http://authors/#{represented.id}" }
      end
    end

    nested :relationships, inherit: true do
      property :editor, type: "author" do
        include Roar::JSON::JSONAPI
        include Roar::JSON
        include Roar::Hypermedia
        type :editors

        property :id
        property :email
        link(:self) { "http://authors/#{represented.id}" }
      end
    end

    nested :relationships, inherit: true do
      collection :comments, type: "comments" do
        include Roar::JSON::JSONAPI
        include Roar::JSON
        include Roar::Hypermedia
        type :comments

        property :id
        property :body
        link(:self) { "http://comments/#{represented.id}" }
      end
    end

    nested :included do
      property :author, decorator: bla[:extend].(nil).representable_attrs.get(:author)[:extend].(nil)

      property :editor, decorator: bla[:extend].(nil).representable_attrs.get(:editor)[:extend].(nil)
      collection :comments, decorator: bla[:extend].(nil).representable_attrs.get(:comments)[:extend].(nil)
    end
  end

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
               :links=>{"self"=>"http://JsonapiRenderTest::Article/"},
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
end