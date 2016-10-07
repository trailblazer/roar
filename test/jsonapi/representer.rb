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

  # top-level link.
  link :self, toplevel: true do |options|
    if options
      "//articles?page=#{options[:page]}&per_page=#{options[:per_page]}"
    else
      "//articles"
    end
  end

  # attributes: {}
  property :id
  property :title


  # resource object links
  link(:self) { "http://#{represented.class}/#{represented.id}" }

  # relationships
  has_one :author, class: Author, populator: ::Representable::FindOrInstantiate do # populator is for parsing, only.
    type :authors

    property :id
    property :email
    link(:self) { "http://authors/#{represented.id}" }
  end

  has_one :editor do
    type :editors

    property :id
    property :email
    # No self link for editors because we want to make sure the :links option does not appear in the hash.
  end

  has_many :comments, class: Comment, populator: ::Representable::FindOrInstantiate do
    type :comments

    property :id
    property :body
    link(:self) { "http://comments/#{represented.id}" }
  end
end
