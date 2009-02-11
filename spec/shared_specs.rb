require File.dirname(__FILE__) + '/spec_helper.rb'

describe "freezable xml reference", :shared => true do
  describe "with :frozen option" do
    it "should be frozen" do
      @frozen.frozen?.should be_true
    end
  end

  describe "without :frozen option" do
    it "should not be frozen" do
      @unfrozen.frozen?.should be_false
    end
  end
end