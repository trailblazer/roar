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
      [song].extend(rpr).to_json.must_equal %{{"collection":{"version":"1.0","href":"//songs/","items":[{"href":"//songs/scarifice","links":[{"rel":"download","href":"//songs/scarifice.mp3"},{"rel":"stats","href":"//songs/scarifice/stats"}],"data":[{"name":"title","value":"scarifice"},{"name":"length","value":43}]}],"links":[{"rel":"feed","href":"//songs/feed"}]}}}
    end
  end
end