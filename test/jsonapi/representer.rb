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
    property :author, class: Author, type: "author", populator: ::Representable::FindOrInstantiate do
      include Roar::JSON::JSONAPI
      include Roar::JSON
      include Roar::Hypermedia
      type :authors

      property :id
      property :email
      link(:self) { "http://authors/#{represented.id}" }

      def from_document(hash)
        hash
      end
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
    collection :comments, class: Comment, type: "comments", populator: ::Representable::FindOrInstantiate do
      include Roar::JSON::JSONAPI
      include Roar::JSON
      include Roar::Hypermedia
      type :comments

      property :id
      property :body
      link(:self) { "http://comments/#{represented.id}" }

      def from_document(hash)
        hash
      end
    end
  end

  nested :included do
    property :author, decorator: bla[:extend].(nil).representable_attrs.get(:author)[:extend].(nil)

    property :editor, decorator: bla[:extend].(nil).representable_attrs.get(:editor)[:extend].(nil)
    collection :comments, decorator: bla[:extend].(nil).representable_attrs.get(:comments)[:extend].(nil)
  end
end