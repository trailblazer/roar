class JSONAPIFieldsetsTest < Minitest::Spec
  describe "Single Resource Object With Options" do
    class DocumentSingleResourceObjectDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :articles

      property :id
      property :title
      property :author
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

    subject { DocumentSingleResourceObjectDecorator.new(Article.new(1, "My Article", "Some Author")).to_json(include: [:title, :id]) }
    it { subject.must_equal document.to_json }
  end

  describe "Collection Resources With Options" do
    class CollectionResourceObjectDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :articles

      property :id
      property :title
      property :author
    end

    let(:document) {
      {
        "data" => [
          {
            "type" => "articles",
            "id" => "1",
            "attributes" => {
              "title" => "My Article"
            }
          },
          {
            "type" => "articles",
            "id" => "2",
            "attributes" => {
              "title" => "My Other Article"
            }
          }
        ]
      }
    }

    subject do
      CollectionResourceObjectDecorator.for_collection.new([
        Article.new(1, "My Article", "Some Author"),
        Article.new(2, "My Other Article", "Some Author")
      ]).to_json(include: [:title, :id])
    end
    it { subject.must_equal document.to_json }
  end
end