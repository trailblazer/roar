require "test_helper"
require "roar/json/json_api"
require "json"
require "jsonapi/representer"

class JsonapiPostTest < MiniTest::Spec
  describe "Parse" do
    let(:post_article) {
      {
        "data" => {
          "type" => "articles",
          "attributes" => {
            "title" => "Ember Hamster",
          },
          # that does do `photo.photographer= Photographer.find(9)`
          "relationships" => {
            "author" => {
              "data" => { "type" => "people", "id" => "9", "name" => "Celsito" } # FIXME: what should happen if i add `"name" => "Celsito"` here? should that be read or not?
            },
            "comments" => {
              "data" => [
                { "type" => "comment", "id" => "2" },
                { "type" => "comment", "id" => "3" },
              ]
            }

          }
        }
      }
    }

    subject { ArticleDecorator.new(Article.new(nil, nil, nil, nil, [])).from_json(post_article.to_json) }

    it do
      subject.title.must_equal "Ember Hamster"
      subject.author.id.must_equal "9"
      subject.author.email.must_equal "9@nine.to"
      # subject.author.name.must_equal nil

      subject.comments.must_equal [Comment.new("2"), Comment.new("3")]
    end
  end

  describe "Parse Simple" do
    let(:post_article) {
      {
        "data" => {
          "type" => "articles",
          "attributes" => {
            "title" => "Ember Hamster",
          }
        }
      }
    }

    subject { ArticleDecorator.new(Article.new(nil, nil, nil, nil, [])).from_json(post_article.to_json) }

    it do
      subject.title.must_equal "Ember Hamster"
    end
  end

  describe "Parse Badly Formed Document" do
    let(:post_article) {
      { "title" => "Ember Hamster" }
    }

    subject { ArticleDecorator.new(Article.new(nil, nil, nil, nil, [])).from_json(post_article.to_json) }

    it do
      subject.title.must_equal nil
    end
  end
end
