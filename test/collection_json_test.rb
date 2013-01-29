require 'test_helper'

class CollectionJsonTest < MiniTest::Spec
  subject { Object.new().extend(rpr)  }
  let(:song) { OpenStruct.new(:title => "scarifice", :length => 43) }

  ItemRepresenter = Module.new do
    include Roar::Representer::JSON
    include Roar::Representer::Feature::Hypermedia

    property :href
    def href
      "//songs/scarifice"
    end

    #collection :data
    #def data
    #end

    def to_hash(*)
      hash = super
      data = []
      [:title, :length].each do |n| # TODO: get all except :links etc.
        v = hash.delete(n.to_s)
        data << {:name => n, :value => v} # TODO: get :prompt from Definition.
      end
      hash[:data] = data
      hash
    end



    property :title, :prompt => "Song title"
    property :length, :prompt => "Song length"

    link(:download) { "//songs/scarifice.mp3" }
    link(:stats) { "//songs/scarifice/stats" }
  end

  # TODO: provide automatic copying from the ItemRepresenter here.
  TemplateRepresenter = Module.new do
    include Roar::Representer::JSON

    property :title, :prompt => "Song title", :render_nil => true
    property :length, :prompt => "Song length", :render_nil => true

    def to_hash(*)
      hash = super
      data = []
      hash.keys.each do |n| # TODO: get all except :links etc.
        v = hash.delete(n.to_s)
        data << {:name => n, :value => v} # TODO: get :prompt from Definition.
      end
      hash[:data] = data
      hash
    end
  end

  QueriesRepresenter = Module.new do
    include Roar::Representer::JSON
    include Roar::Representer::Feature::Hypermedia

    link :search do
      {:href => "//search", :data => [{:name => "q", :value => ""}]}
    end
  end

  #puts Object.new.extend(QueriesRepresenter).to_json


  representer_for do
    include Roar::Representer::JSON
    include Roar::Representer::Feature::Hypermedia
    self.representation_wrap= :collection
    property :version, :writeable => false
    property :href
    collection :items, :extend => ItemRepresenter
    def items
      self
    end
    property :template, :extend => TemplateRepresenter
    def template
      OpenStruct.new  # TODO: handle preset values.
    end
    #class QueryLinksDefinition < Roar::Representer::Feature::Hypermedia::LinksDefinition
    #end
    collection :queries, :extend => Roar::Representer::JSON::HyperlinkRepresenter
    def queries
      compile_links_for QueriesRepresenter.representable_attrs.first
    end

    def version
      "1.0"
    end

    def href
      "//songs/"
    end

    link(:feed) { "//songs/feed" }
  end


  describe "item" do
    subject { song.extend(ItemRepresenter)}

    it "renders" do
      subject.to_json.must_equal %{{"href":"//songs/scarifice","links":[{"rel":"download","href":"//songs/scarifice.mp3"},{"rel":"stats","href":"//songs/scarifice/stats"}],"data":[{"name":"title","value":"scarifice"},{"name":"length","value":43}]}}
    end
  end

  describe "#to_json" do
    it "renders document" do
      [song].extend(rpr).to_json.must_equal %{{"collection":{"version":"1.0","href":"//songs/","items":[{"href":"//songs/scarifice","links":[{"rel":"download","href":"//songs/scarifice.mp3"},{"rel":"stats","href":"//songs/scarifice/stats"}],"data":[{"name":"title","value":"scarifice"},{"name":"length","value":43}]}],"template":{"data":[{"name":"title","value":null},{"name":"length","value":null}]},"queries":[{"rel":"search","href":"//search","data":[{"name":"q","value":""}]}],"links":[{"rel":"feed","href":"//songs/feed"}]}}}
    end
  end
end