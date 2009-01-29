require File.join(File.dirname(__FILE__), '..', 'test_helper')

#      Parent        |    Child
#  :from  | no :from |
# -------------------|--------------
#  :from  | xml_name | xml_name-d
#  value  |  value   |
# -------------------|--------------
#  :from  | parent's |
#  value  | accessor | un-xml_name-d
#         |  name    |

class Child
  include ROXML
end

class NamedChild
  include ROXML

  xml_name :xml_name_of_child
end

class ParentOfNamedChild
  include ROXML

  xml_name :parent
  xml_accessor :child_accessor_name, NamedChild
end

class ParentOfNamedChildWithFrom
  include ROXML

  xml_name :parent
  xml_accessor :child_accessor_name, NamedChild, :from => 'child_from_name'
end

class ParentOfUnnamedChild
  include ROXML

  xml_name :parent
  xml_accessor :child_accessor_name, Child
end

class ParentOfUnnamedChildWithFrom
  include ROXML

  xml_name :parent
  xml_accessor :child_accessor_name, Child, :from => 'child_from_name'
end

class TestXMLName < Test::Unit::TestCase
  def test_from_always_dominates_attribute_name_xml_name_or_not
    parent = ParentOfNamedChildWithFrom.new
    parent.child_accessor_name = Child.new

    assert_equal "<parent><child_from_name/></parent>", parent.to_xml.to_s.gsub(/[\n ]/, '')

    parent = ParentOfUnnamedChildWithFrom.new
    parent.child_accessor_name = Child.new

    assert_equal "<parent><child_from_name/></parent>", parent.to_xml.to_s.gsub(/[\n ]/, '')
  end

  def test_attribute_name_comes_from_the_xml_name_value_if_present
    parent = ParentOfNamedChild.new
    parent.child_accessor_name = Child.new

    assert_equal "<parent><xml_name_of_child/></parent>", parent.to_xml.to_s.gsub(/[\n ]/, '')
  end

  def test_attribute_name_comes_from_parent_accessor_by_default
    parent = ParentOfUnnamedChild.new
    parent.child_accessor_name = Child.new

    assert_equal "<parent><child_accessor_name/></parent>", parent.to_xml.to_s.gsub(/[\n ]/, '')
  end

  def test_it_should_be_inherited
    class_with_inherited_name = Class.new(ParentOfNamedChild)
    assert_equal :parent, class_with_inherited_name.tag_name
  end

  def test_it_should_be_inherited_over_multiple_levels
    class_with_inherited_name = Class.new(Class.new(ParentOfNamedChild))
    assert_equal :parent, class_with_inherited_name.tag_name
  end

  def test_named_books_picked_up
    named = Library.from_xml(fixture(:library))
    assert named.books
    assert_equal :book, named.books.first.tag_name
  end

  def test_nameless_books_missing
    nameless = LibraryWithBooksOfUnderivableName.from_xml(fixture(:library))
    assert nameless.novels.empty?
  end

  def test_tag_name
    assert_equal :dictionary, DictionaryOfTexts.tag_name

    dict = DictionaryOfTexts.from_xml(fixture(:dictionary_of_texts))

    assert_equal :dictionary, dict.tag_name
  end

  def test_tag_refs
    assert_equal 'definition', DictionaryOfTexts.tag_refs_without_deprecation.first.name
    assert_equal 'word', DictionaryOfTexts.tag_refs_without_deprecation.first.hash.key.name
    assert_equal 'meaning', DictionaryOfTexts.tag_refs_without_deprecation.first.hash.value.name

    dict = DictionaryOfTexts.from_xml(fixture(:dictionary_of_texts))

    assert_equal 'definition', dict.tag_refs_without_deprecation.first.name
    assert_equal 'word', dict.tag_refs_without_deprecation.first.hash.key.name
    assert_equal 'meaning', dict.tag_refs_without_deprecation.first.hash.value.name
  end

  def test_roxml_attrs
    assert_equal 'definition', DictionaryOfTexts.roxml_attrs.first.name
    assert_equal 'word', DictionaryOfTexts.roxml_attrs.first.hash.key.name
    assert_equal 'meaning', DictionaryOfTexts.roxml_attrs.first.hash.value.name
  end

  def test_xml_name_query_is_deprecated
    # This query should go when the XML_NAME_WARNING stuff goes
    assert_deprecated do
      NamedChild.xml_name?
    end
  end
end