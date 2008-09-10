require File.join(File.dirname(__FILE__), '..', 'test_helper')

def to_xml_test(*names)
  names.each do |name|
    define_method "test_#{name}" do
      dict = name.to_s.camelize.constantize.parse(fixture(name))
      assert_equal xml_fixture(name), dict.to_xml
    end
  end
end

class TestHashToXml < Test::Unit::TestCase
  to_xml_test :dictionary_of_attrs, :dictionary_of_mixeds, :dictionary_of_texts
end