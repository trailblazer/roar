require 'test_helper'

class XmlHypermediaTest < MiniTest::Spec
  describe "Hypermedia API" do
    before do
      @c = Class.new do
        include Roar::Representer::XML
        self.representation_name= :wuff
        
        property :id
        
        link :self do "http://self" end
        link :next do "http://next/#{id}" end
      end
    end
    
    describe "#deserialize" do
      it "extracts links from XML" do
        @r = @c.deserialize(%{
        <order>
          <link rel="self" href="http://self">
        </order>
        })
        
        assert_kind_of Roar::Representer::Feature::Hypermedia::LinkCollection, @r.links
        assert_equal 1, @r.links.size
        assert_equal({"rel"=>"self", "href"=>"http://self"}, @r.links.first.to_attributes) 
      end
      
      it "works even if there are no links in the document" do
        @r = @c.deserialize(%{<order/>})
        assert_equal [], @r.links
      end
    end
    
    # FIXME: MiniTest::Spec swallows this block:
    #describe "#serialize" do
      it "renders <link> correctly in XML" do
        assert_xml_equal %{
        <wuff>
          <id>1</id>
          <link rel="self" href="http://self"/>
          <link rel="next" href="http://next/1"/>
        </wuff>}, @c.from_attributes({"id" => 1}).serialize
      end
      
      it "skips link when there are no" do
        rep = Class.new do
          include Roar::Representer::XML
          self.representation_name= :wuff
          property :id
        end.from_attributes(:id => 1)
        
        assert_xml_equal %{
        <wuff>
          <id>1</id>
        </wuff>}, rep.serialize
      end
    #end
  end
end
