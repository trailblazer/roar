require "test_helper"

class HyperlinkTest < MiniTest::Spec
  subject { Roar::Hypermedia::Hyperlink.new(:rel => "self", "href" => "http://self", "data-whatever" => "Hey, @myabc") }

  it "accepts string keys in constructor" do
    assert_equal "Hey, @myabc", subject.send("data-whatever")
  end

  it "responds to #rel" do
    assert_equal "self", subject.rel
  end

  it "responds to #href" do
    assert_equal "http://self", subject.href
  end

  it "responds to #replace with string keys" do
    subject.replace("rel" => "next")
    assert_equal nil, subject.href
    assert_equal "next", subject.rel
  end

  it "responds to #each and implements Enumerable" do
    assert_equal ["rel:self", "href:http://self", "data-whatever:Hey, @myabc"], subject.collect { |k,v| "#{k}:#{v}" }
  end

  describe "JSON" do
    it { Roar::JSON::HyperlinkDecorator.new(subject).to_json.must_equal %{{"rel":"self","href":"http://self","data-whatever":"Hey, @myabc"}} }
  end

  describe "Config inheritance" do
    it "doesn't mess up with inheritable_array" do  # FIXME: remove this test when uber is out.
      OpenStruct.new.extend( Module.new do
                include Roar::JSON
                include(Module.new do
                                    include Roar::JSON
                                    include Roar::Hypermedia

                                    property :bla

                                    link( :self) {"bo"}

                                    #puts "hey ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                                    #puts representable_attrs.inheritable_array(:links).inspect
                                  end)


                #puts representable_attrs.inheritable_array(:links).inspect

                property :blow
                include Roar::Hypermedia
                link(:bla) { "boo" }
              end).to_hash.must_equal({"links"=>[{"rel"=>"self", "href"=>"bo"}, {"rel"=>"bla", "href"=>"boo"}]})
    end
  end
end
