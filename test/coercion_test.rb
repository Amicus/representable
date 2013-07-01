require 'test_helper'
require 'representable/coercion'
require 'representable/decorator/coercion'

class VirtusCoercionTest < MiniTest::Spec
  class Song  # note that we don't define accessors for the properties here. ### FIXME
    attr_accessor :title, :composed_at
  end

  let (:date) { DateTime.parse("Fri, 18 Nov 1983 00:00:00 +0000") }

  describe "Coercion with Virtus" do
    describe "on object level" do
      module SongRepresenter
        include Representable::JSON
        include Representable::Coercion
        property :composed_at,  :type => DateTime
        property :track,        :type => Integer
        property :title # no coercion.
      end

      it "coerces properties in #from_json" do
        song = Song.new.extend(SongRepresenter).from_json('{"composed_at":"November 18th, 1983","track":"18","title":"Scarified"}')
        assert_kind_of DateTime, song.composed_at
        assert_equal date, song.composed_at
        assert_equal 18, song.track
        song.title.must_equal "Scarified"
      end

       it "coerces when rendering" do
         song = Song.new.extend(SongRepresenter)
         song.title       = "Scarified"
         song.composed_at = "Fri, 18 Nov 1983"

         song.to_hash.must_equal({"title" => "Scarified", "composed_at" => date})
       end
    end


     describe "on class level" do
       class ImmigrantSong
         include Representable::JSON
         include Representable::Coercion

         property :composed_at,  :type => DateTime, :default => "May 12th, 2012"
         property :track,        :type => Integer
       end

       it "coerces into the provided type" do
         song = ImmigrantSong.new.from_json("{\"composed_at\":\"November 18th, 1983\",\"track\":\"18\"}")
         assert_equal date, song.composed_at
         assert_equal 18, song.track
       end

       it "respects the :default options" do
         song = ImmigrantSong.new.from_json("{}")
         assert_kind_of DateTime, song.composed_at
         assert_equal DateTime.parse("Mon, 12 May 2012 00:00:00 +0000"), song.composed_at
       end
     end

     describe "on decorator" do
       class SongRepresentation < Representable::Decorator
         include Representable::JSON
         include Representable::Decorator::Coercion

         property :composed_at, :type => DateTime
         property :title
       end

       it "coerces when parsing" do
         song = SongRepresentation.new(OpenStruct.new).from_json("{\"composed_at\":\"November 18th, 1983\", \"title\": \"Scarified\"}")
         song.must_be_kind_of OpenStruct
         song.composed_at.must_equal date
         song.title.must_equal "Scarified"
       end

      it "coerces when rendering" do
        SongRepresentation.new(
          OpenStruct.new(
            :composed_at  => "November 18th, 1983",
            :title        => "Scarified"
          )
        ).to_hash.must_equal({"composed_at"=>DateTime.parse("Fri, 18 Nov 1983"), "title"=>"Scarified"})
      end
    end
  end
end
