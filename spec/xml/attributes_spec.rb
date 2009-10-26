require 'spec/spec_helper'

describe ROXML::XMLAttributeRef do
  before do
    @xml = ROXML::XML::Parser.parse %(
<myxml>
  <node name="first" />
  <node name="second" />
  <node name="third" />
</myxml>)
  end
  
  context "plain vanilla" do
    before do
      @ref = ROXML::XMLAttributeRef.new(OpenStruct.new(:name => 'name', :wrapper => 'node', :array? => false), RoxmlObject.new)
    end

    it "should return one instance" do
      @ref.value_in(@xml).should == "first"
    end
    it "should output one instance"
  end
  
  context "with :as => []" do
    before do
      @ref = ROXML::XMLAttributeRef.new(OpenStruct.new(:name => 'name', :wrapper => 'node', :array? => true), RoxmlObject.new)
    end

    it "should collect all instances" do
      @ref.value_in(@xml).should == ["first", "second", "third"]
    end

    it "should output all instances" do
      xml = ROXML::XML::Node.create('myxml')
      @ref.update_xml(xml, ["first", "second", "third"])
      xml.to_s.squeeze(' ').should == @xml.root.to_s.squeeze(' ')
    end
  end
end