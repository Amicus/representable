require 'test_helper'

class GenericTest < MiniTest::Spec
# one day, this file will contain all engine-independent test cases. one day...
  let (:new_album)  { OpenStruct.new.extend(representer) }
  let (:album)      { OpenStruct.new(:songs => ["Fuck Armageddon"]).extend(representer) }
  let (:song) { OpenStruct.new(:title => "Resist Stance") }
  let (:song_representer) { Module.new do include Representable::Hash; property :title end  }


  describe "::collection" do
    representer! do
      collection :songs
    end

    it "initializes property with empty array" do
      new_album.from_hash({})
      new_album.songs.must_equal [] # DISCUSS: do we really want this?
    end

    it "overrides property with empty array" do
      album.from_hash({})
      album.songs.must_equal [] # DISCUSS: do we really want this?
    end
  end


  describe "property with instance: { nil }" do # TODO: introduce :representable option?
    representer!(:inject => :song_representer) do
      property :song, :instance => lambda { |*| nil }, :extend => song_representer
    end

    let (:hit) { hit = OpenStruct.new(:song => song).extend(representer) } # note that song is already representable.

    it "calls #to_hash on song instance, nothing else" do
      hit.to_hash.must_equal("song"=>{"title"=>"Resist Stance"})
    end

    it "calls #from_hash on the existing song instance, nothing else" do
      song_id = hit.song.object_id
      hit.from_hash("song"=>{"title"=>"Suffer"})
      hit.song.title.must_equal "Suffer"
      hit.song.object_id.must_equal song_id
    end
  end


  describe "property with parse_strategy: :sync" do # TODO: introduce :representable option?
    representer!(:inject => :song_representer) do
      property :song, :parse_strategy => :sync, :extend => song_representer
    end

    let (:hit) { hit = OpenStruct.new(:song => song).extend(representer) } # note that song is already representable.

    it "calls #to_hash on song instance, nothing else" do
      hit.to_hash.must_equal("song"=>{"title"=>"Resist Stance"})
    end

    it "calls #from_hash on the existing song instance, nothing else" do
      song_id = hit.song.object_id

      hit.from_hash("song"=>{"title"=>"Suffer"})

      hit.song.title.must_equal "Suffer"
      hit.song.object_id.must_equal song_id
    end
  end

  # FIXME: there's a bug with XML and the collection name!
  {
    :hash => [Representable::Hash, {"songs"=>[{"title"=>"Resist Stance"}]}, {"songs"=>[{"title"=>"Suffer"}]}],
    #:json => [Representable::JSON, "{\"song\":{\"name\":\"Alive\"}}", "{\"song\":{\"name\":\"You've Taken Everything\"}}"],
    :xml  => [Representable::XML, "<open_struct><song><title>Resist Stance</title></song></open_struct>", "<open_struct><songs><title>Suffer</title></songs></open_struct>"],
    #:yaml => [Representable::YAML, "---\nsong:\n  name: Alive\n", "---\nsong:\n  name: You've Taken Everything\n"],
  }.each do |format, cfg|
    mod, output, input = cfg


    describe "[#{format}] collection with :parse_strategy: :sync" do # TODO: introduce :representable option?
      let (:format) { format }
      representer!(:module => mod, :name => :song_representer) do
        property :title
        self.representation_wrap = :song if format == :xml
      end

      representer!(:inject => :song_representer, :module => mod) do
        collection :songs, :parse_strategy => :sync, :extend => song_representer
      end

      let (:album) { OpenStruct.new(:songs => [song]).extend(representer) }

      it "calls #to_hash on song instances, nothing else" do
        render(album).must_equal_document(output)
      end

      it "calls #from_hash on the existing song instance, nothing else" do
        collection_id = album.songs.object_id
        song          = album.songs.first
        song_id       = song.object_id

        parse(album, input)

        album.songs.first.title.must_equal "Suffer"
        song.title.must_equal "Suffer"
        #album.songs.object_id.must_equal collection_id # TODO: don't replace!
        song.object_id.must_equal song_id
      end
    end
  end

  def render(object)
    AssertableDocument.new(object.send("to_#{format}"), format)
  end

  def parse(object, input)
    object.send("from_#{format}", input)
  end

  class AssertableDocument
    attr_reader :document

    def initialize(document, format)
      @document, @format = document, format
    end

    def must_equal_document(*args)
      return document.must_equal_xml(*args) if @format == :xml
      document.must_equal(*args)
    end
  end


  describe "mix :extend and inline representers" do
    representer! do
      rpr_module = Module.new do
        include Representable::Hash
        property :title
      end
      property :song, :extend => rpr_module do
        property :artist
      end
    end

    it do OpenStruct.new(:song => OpenStruct.new(:title => "The Fever And The Sound", :artist => "Strung Out")).extend(representer).
      to_hash.
      must_equal({"song"=>{"artist"=>"Strung Out", "title"=>"The Fever And The Sound"}})
    end
  end
end