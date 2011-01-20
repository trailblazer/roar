require 'test_helper'

class RepresenterTest < MiniTest::Spec
  Collection = Roar::Representation::UnwrappedCollection
  
  describe "UnwrappedCollection" do
    before do
      @l = Collection.new([{:number => 1}, {:number => 2}])
      @xml = Builder::XmlMarkup.new
    end
    
    it "#to_xml returns contained items without a wrapping tag" do
      @l.to_xml(:builder => @xml) # TODO: replace with a simpler system.
      assert_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?><hash><number type=\"integer\">1</number></hash><?xml version=\"1.0\" encoding=\"UTF-8\"?><hash><number type=\"integer\">2</number></hash>", @xml.target!
    end
    
    it "#to_xml accepts options" do
      @l.to_xml(:builder => @xml, :skip_instruct => true, :skip_types => true)
      assert_equal "<hash><number>1</number></hash><hash><number>2</number></hash>", @xml.target!
    end
    
    it "works in a nested hash" do
      assert_equal "<hash>
  <order>
    <position>
      <article>Peanut Butter</article>
      <amount>1</amount>
    </position>
    <position>
      <article>Hoepfner Pils</article>
      <amount>2</amount>
    </position>
  </order>\n</hash>\n", {:order => {:position => Collection.new([
{:article => "Peanut Butter", :amount => 1}, 
{:article => "Hoepfner Pils", :amount => 2}])}}.to_xml(:skip_instruct => true, :skip_types => true)
    end
    
    it "works with contained objects that respond to #to_xml themselves" do
      class Method
        def initialize(verb) @verb = verb end
        def to_xml(o) o[:builder].tag!(:method, :type => @verb) end
      end
      
      @l = Collection.new([Method.new(:PUT), Method.new(:GET)])
      @l.to_xml(:builder => @xml)
      assert_equal "<method type=\"PUT\"/><method type=\"GET\"/>", @xml.target!
    end 
  end
end
    
