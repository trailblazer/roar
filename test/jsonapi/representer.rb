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

  link :self, toplevel: true do
  # for_collection.link(:self) do
    "//articles"
  end

  property :id
  property :title


  link(:self) { "http://#{represented.class}/" }

  has_one :author, class: Author, type: "author", populator: ::Representable::FindOrInstantiate do
    type :authors

    property :id
    property :email
    link(:self) { "http://authors/#{represented.id}" }
  end

  has_one :editor, type: "author" do
    type :editors

    property :id
    property :email
    link(:self) { "http://authors/#{represented.id}" }
  end

  has_many :comments, class: Comment, type: "comments", populator: ::Representable::FindOrInstantiate do
    type :comments

    property :id
    property :body
    link(:self) { "http://comments/#{represented.id}" }
  end

  bla = representable_attrs.get(:relationships)
  nested :included do
    property :author, decorator: bla[:extend].(nil).representable_attrs.get(:author)[:extend].(nil)

    property :editor, decorator: bla[:extend].(nil).representable_attrs.get(:editor)[:extend].(nil)
    collection :comments, decorator: bla[:extend].(nil).representable_attrs.get(:comments)[:extend].(nil)
  end
end