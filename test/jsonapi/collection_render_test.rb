require "test_helper"
require "roar/json/json_api"
require "json"
require "jsonapi/representer"

class JsonapiCollectionRenderTest < MiniTest::Spec
  let (:article) { Article.new(1, "Health walk", Author.new(2), Author.new("editor:1"), [Comment.new("comment:1", "Ice and Snow"),Comment.new("comment:2", "Red Stripe Skank")])}
  let (:article2) { Article.new(2, "Virgin Ska", Author.new("author:1"), nil, [Comment.new("comment:3", "Cool song!")]) }
  let (:article3) { Article.new(3, "Gramo echo", Author.new("author:1"), nil, [Comment.new("comment:4", "Skalar")]) }
  let (:decorator) { ArticleDecorator.for_collection.new([article, article2, article3]) }

  it "renders full document" do
    pp hash = decorator.to_hash

    hash.must_equal(
      {:data=>
        [{:type=>"articles",
          :id=>"1",
          :attributes=>{"title"=>"Health walk"},
          :relationships=>
           {"author"=>
             {:data=>{:type=>"authors", :id=>"2"},
              :links=>{"self"=>"http://authors/2"}},
            "editor"=>
             {:data=>{:type=>"editors", :id=>"editor:1"}},
            "comments"=>
             {:data=>
               [{:type=>"comments",
                 :id=>"comment:1"},
                {:type=>"comments",
                 :id=>"comment:2"}],
              :links=>{"self"=>"http://comments/comment:2"}}},
          :links=>{"self"=>"http://Article/1"}},
         {:type=>"articles",
          :id=>"2",
          :attributes=>{"title"=>"Virgin Ska"},
          :relationships=>
           {"author"=>
             {:data=>{:type=>"authors", :id=>"author:1"},
              :links=>{"self"=>"http://authors/author:1"}},
            "comments"=>
             {:data=>
               [{:type=>"comments",
                 :id=>"comment:3"}],
              :links=>{"self"=>"http://comments/comment:3"}}},
          :links=>{"self"=>"http://Article/2"}},
          {:type=>"articles",
           :id=>"3",
           :attributes=>{"title"=>"Gramo echo"},
           :relationships=>
            {"author"=>
              {:data=>{:type=>"authors", :id=>"author:1"},
               :links=>{"self"=>"http://authors/author:1"}},
             "comments"=>
              {:data=>
                [{:type=>"comments", :id=>"comment:4"}],
               :links=>{"self"=>"http://comments/comment:4"}}},
           :links=>{"self"=>"http://Article/3"}}],
       :links=>{"self"=>"//articles"},
       :included=>
        [{:type=>"authors", :id=>"2", :links=>{"self"=>"http://authors/2"}},
         {:type=>"editors",
          :id=>"editor:1"},
         {:type=>"comments",
          :id=>"comment:1",
          :attributes=>{"body"=>"Ice and Snow"},
          :links=>{"self"=>"http://comments/comment:1"}},
         {:type=>"comments",
          :id=>"comment:2",
          :attributes=>{"body"=>"Red Stripe Skank"},
          :links=>{"self"=>"http://comments/comment:2"}},
         {:type=>"authors",
          :id=>"author:1",
          :links=>{"self"=>"http://authors/author:1"}},
         {:type=>"comments",
          :id=>"comment:3",
          :attributes=>{"body"=>"Cool song!"},
          :links=>{"self"=>"http://comments/comment:3"}},
         {:type=>"comments",
          :id=>"comment:4",
          :attributes=>{"body"=>"Skalar"},
          :links=>{"self"=>"http://comments/comment:4"}}]
      }
    )
  end

  it "included: false suppresses compound docs" do
    decorator.to_hash(included: false).must_equal(
      {:data=>
        [{:type=>"articles",
          :id=>"1",
          :attributes=>{"title"=>"Health walk"},
          :relationships=>
           {"author"=>
             {:data=>{:type=>"authors", :id=>"2"},
              :links=>{"self"=>"http://authors/2"}},
            "editor"=>
             {:data=>{:type=>"editors", :id=>"editor:1"}},
            "comments"=>
             {:data=>
               [{:type=>"comments",
                 :id=>"comment:1"},
                {:type=>"comments",
                 :id=>"comment:2"}],
              :links=>{"self"=>"http://comments/comment:2"}}},
          :links=>{"self"=>"http://Article/1"}},
         {:type=>"articles",
          :id=>"2",
          :attributes=>{"title"=>"Virgin Ska"},
          :relationships=>
           {"author"=>
             {:data=>{:type=>"authors", :id=>"author:1"},
              :links=>{"self"=>"http://authors/author:1"}},
            "comments"=>
             {:data=>
               [{:type=>"comments",
                 :id=>"comment:3"}],
              :links=>{"self"=>"http://comments/comment:3"}}},
          :links=>{"self"=>"http://Article/2"}},
          {:type=>"articles",
           :id=>"3",
           :attributes=>{"title"=>"Gramo echo"},
           :relationships=>
            {"author"=>
              {:data=>{:type=>"authors", :id=>"author:1"},
               :links=>{"self"=>"http://authors/author:1"}},
             "comments"=>
              {:data=>
                [{:type=>"comments",
                  :id=>"comment:4"}],
               :links=>{"self"=>"http://comments/comment:4"}}},
           :links=>{"self"=>"http://Article/3"}}],
       :links=>{"self"=>"//articles"},
      }
    )
  end

  it "passes :user_options to toplevel links when rendering" do
    hash = decorator.to_hash(user_options: { page: 2, per_page: 10 })
    hash[:links].must_equal({
      "self" => "//articles?page=2&per_page=10"
    })
  end

  describe "Fetching Resources (empty collection)" do
    let(:document) {
      {
        "data" => [],
        "links" => {
          "self" => "//articles"
        },
      }
    }

    let(:articles) { [] }
    subject { ArticleDecorator.for_collection.new(articles).to_json }

    it { subject.must_equal document.to_json }
  end
end
