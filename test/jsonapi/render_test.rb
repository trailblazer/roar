require "test_helper"
require "roar/json/json_api"
require "json"
require "jsonapi/representer"

class JsonapiRenderTest < MiniTest::Spec
  let (:article) { Article.new(1, "Health walk", Author.new(2), Author.new("editor:1"), [Comment.new("comment:1", "Ice and Snow"),Comment.new("comment:2", "Red Stripe Skank")]) }
  let (:decorator) { ArticleDecorator.new(article) }

  it "renders full document" do
    pp hash = decorator.to_hash

# puts hash.to_json
    hash.must_equal(
    {
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
              {:data=>{:type=>"editors", :id=>"editor:1"}},
             "comments"=>
              {:data=>
                [
                  {
                    :type=>"comments",
                    :id=>"comment:1"
                  },
                  {
                    :type=>"comments",
                    :id=>"comment:2"
                  }
                ], # FIXME.
               :links=>{"self"=>"http://comments/comment:2"}}}, # FIXME: this only works when a relationship is present.

          :links=>{"self"=>"http://Article/1"},

        },
      :included=>
        [
          {
            :type=>"authors",
            :id=>"2",
            :links=>{"self"=>"http://authors/2"}
          },
          {
            :type=>"editors",
            :id=>"editor:1"
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
          ],
        :meta=>{"reviewers"=>["Christian Bernstein"], "reviewer_initials"=>"C.B."}
        })

  end

  it "included: false suppresses compound docs" do
    decorator.to_hash(included: false).must_equal(
      {
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
                {:data=>{:type=>"editors", :id=>"editor:1"}},
               "comments"=>
                {:data=>
                  [
                    {
                      :type=>"comments",
                      :id=>"comment:1"
                    },
                    {
                      :type=>"comments",
                      :id=>"comment:2"
                    }
                  ], # FIXME.
                 :links=>{"self"=>"http://comments/comment:2"}}}, # FIXME: this only works when a relationship is present.
             :links=>{"self"=>"http://Article/1"}
        },
        :meta=>{"reviewers"=>["Christian Bernstein"], "reviewer_initials"=>"C.B."}
      }
    )
  end

  it 'renders additional meta information if meta option supplied' do
    hash = decorator.to_hash('meta' => {
      'copyright' => 'Nick Sutterer', 'reviewers' => []
    })
    hash[:meta]['copyright'].must_equal('Nick Sutterer')
    hash[:meta]['reviewers'].must_equal([])
    hash[:meta]['reviewer_initials'].must_equal('C.B.')
  end

  it 'does not render additonal meta information if meta option is empty' do
    hash = decorator.to_hash('meta' => {})
    hash[:meta]['copyright'].must_be_nil
    hash[:meta]['reviewers'].must_equal(['Christian Bernstein'])
    hash[:meta]['reviewer_initials'].must_equal('C.B.')
  end

  describe "Single Resource Object" do
    class DocumentSingleResourceObjectDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :articles

      property :id
      property :title
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

    let (:collection_document) { {:data=>[{:type=>"articles", :id=>"1", :attributes=>{"title"=>"My Article"}}]} }

    it { DocumentSingleResourceObjectDecorator.new(Article.new(1, 'My Article')).to_json.must_equal document.to_json }
    it { DocumentSingleResourceObjectDecorator.for_collection.new([Article.new(1, 'My Article')]).to_hash.must_equal collection_document }
  end
end
