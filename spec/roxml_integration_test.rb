require 'spec_helper'

require 'test_xml/spec'

describe ROXML, "#xml" do
  class Contributor
    include ROXML

    xml_accessor :role, :from => :attr
    xml_accessor :name
  end



  describe "collections" do
    context ":as => [Item]" do
      class Book
        include ROXML


        xml_accessor :contributors, :as => [Contributor], :tag => :contributor
      end

      it ".from_xml should push collection items to array" do
        book = Book.from_xml(%{
          <book>
            <contributor><name>David Thomas</name></contributor>
            <contributor><name>Andrew Hunt</name></contributor>
            <contributor><name>Chad Fowler</name></contributor>
          </book>
        })
        book.contributors.map(&:name).sort.should == ["David Thomas","Andrew Hunt","Chad Fowler"].sort
      end
      
      it "responds to #to_xml" do
        book = Book.new
        david = Contributor.new
        david.name= "David Thomas"
        chad = Contributor.new
        chad.name= "Chad Fowler"
        book.contributors = [david, chad]
        
        book.to_xml.to_s.should exactly_match_xml %{<book>
            <contributor><name>David Thomas</name></contributor>
            <contributor><name>Chad Fowler</name></contributor>
          </book>}
      end
    end
    
    
    context ":as => []" do
      class Album
        include ROXML
        
        xml_accessor :songs, :as => [], :tag => :song
      end

      it "collects untyped items" do
        album = Album.from_xml(%{
          <album>
            <song>Two Kevins</song>
            <song>Wright and Rong</song>
            <song>Laundry Basket</song>
          </album>
        })
        album.songs.sort.should == ["Laundry Basket", "Two Kevins", "Wright and Rong"].sort
      end
    end
  end
  
  
  
  
  
  
  describe "Definition" do
    context ":as => []" do
      subject do
        ROXML::Definition.new(:songs, :as => [], :tag => :song)
      end
      
      it "responds to #accessor" do
        subject.accessor.should == "songs"
      end
      
      it "responds to #array?" do
        subject.array?.should be_true
      end
      
      it "responds to #name" do
        subject.accessor.should == "songs"
      end
      
      it "responds to #instance_variable_name" do
        subject.instance_variable_name.should == :"@songs"
      end
      
      it "responds to #setter" do
        subject.setter.should == :"songs="
      end
      
      it "responds to #sought_type" do
        subject.sought_type.should == :text
      end
    end
    
    
    context ":as => [Item]" do
      subject do
        class Song; end
        ROXML::Definition.new(:songs, :as => [Song])
      end
      
      it "responds to #sought_type" do
        subject.sought_type.should == Song
      end
    end
    
    
    context ":as => Item" do
      subject do
        class Song; end
        ROXML::Definition.new(:songs, :as => Song)
      end
      
      it "responds to #sought_type" do
        subject.sought_type.should == Song
      end
    end
  end
end
