require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class XmlHypermediaTest < MiniTest::Spec
  describe "Hypermedia API" do
    before do
      @c = Class.new(Roar::Representer::XML) do
        self.representation_name= :wuff
        representable_property :id
        link :self do "http://self" end
        link :next do "http://next/#{id}" end
      end
      @r = @c.new
    end
    
    it "responds to #links" do
      assert_equal nil, @r.links
    end
    
    it "computes links in #from_attributes" do
      @r = @c.from_attributes({"id" => 1})
      assert_equal 2, @r.links.size
      assert_equal({"rel"=>:self, "href"=>"http://self"}, @r.links.first.to_attributes)
      assert_equal({"rel"=>:next, "href"=>"http://next/1"}, @r.links.last.to_attributes) 
    end
    
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
    
    it "renders <link> correctly in XML" do
      assert_xml_equal %{<wuff>
  <id>1</id>
  <link rel="self" href="http://self"/>
  <link rel="next" href="http://next/1"/>
</wuff><expected />}, @c.from_attributes({"id" => 1}).serialize
    end
    
  end
end
