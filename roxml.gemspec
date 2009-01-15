# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{roxml}
  s.version = "2.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ben Woosley", "Zak Mandhro", "Anders Engstrom", "Russ Olsen"]
  s.date = %q{2009-01-15}
  s.description = %q{ROXML is a Ruby library designed to make it easier for Ruby developers to work with XML. Using simple annotations, it enables Ruby classes to be mapped to XML. ROXML takes care of the marshalling and unmarshalling of mapped attributes so that developers can focus on building first-class Ruby classes. As a result, ROXML simplifies the development of RESTful applications, Web Services, and XML-RPC.}
  s.email = %q{ben.woosley@gmail.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = ["History.txt", "MIT-LICENSE", "Manifest.txt", "README.rdoc", "Rakefile", "TODO", "html/index.html", "html/style.css", "lib/roxml.rb", "lib/roxml/extensions/active_support.rb", "lib/roxml/extensions/array.rb", "lib/roxml/extensions/array/conversions.rb", "lib/roxml/extensions/deprecation.rb", "lib/roxml/extensions/string.rb", "lib/roxml/extensions/string/conversions.rb", "lib/roxml/extensions/string/iterators.rb", "lib/roxml/options.rb", "lib/roxml/xml.rb", "lib/roxml/xml/libxml.rb", "lib/roxml/xml/rexml.rb", "roxml.gemspec", "tasks/rspec.rake", "test/bugs/rexml_bugs.rb", "test/fixtures/book_malformed.xml", "test/fixtures/book_pair.xml", "test/fixtures/book_text_with_attribute.xml", "test/fixtures/book_valid.xml", "test/fixtures/book_with_authors.xml", "test/fixtures/book_with_contributions.xml", "test/fixtures/book_with_contributors.xml", "test/fixtures/book_with_contributors_attrs.xml", "test/fixtures/book_with_default_namespace.xml", "test/fixtures/book_with_depth.xml", "test/fixtures/book_with_octal_pages.xml", "test/fixtures/book_with_publisher.xml", "test/fixtures/book_with_wrapped_attr.xml", "test/fixtures/dictionary_of_attr_name_clashes.xml", "test/fixtures/dictionary_of_attrs.xml", "test/fixtures/dictionary_of_guarded_names.xml", "test/fixtures/dictionary_of_mixeds.xml", "test/fixtures/dictionary_of_name_clashes.xml", "test/fixtures/dictionary_of_names.xml", "test/fixtures/dictionary_of_texts.xml", "test/fixtures/library.xml", "test/fixtures/library_uppercase.xml", "test/fixtures/muffins.xml", "test/fixtures/nameless_ageless_youth.xml", "test/fixtures/node_with_attr_name_conflicts.xml", "test/fixtures/node_with_name_conflicts.xml", "test/fixtures/numerology.xml", "test/fixtures/person.xml", "test/fixtures/person_with_guarded_mothers.xml", "test/fixtures/person_with_mothers.xml", "test/mocks/dictionaries.rb", "test/mocks/mocks.rb", "test/release/dependencies_test.rb", "test/test_helper.rb", "test/unit/array_test.rb", "test/unit/freeze_test.rb", "test/unit/inheritance_test.rb", "test/unit/options_test.rb", "test/unit/overriden_output_test.rb", "test/unit/roxml_test.rb", "test/unit/string_test.rb", "test/unit/to_xml_test.rb", "test/unit/xml_attribute_test.rb", "test/unit/xml_block_test.rb", "test/unit/xml_bool_test.rb", "test/unit/xml_construct_test.rb", "test/unit/xml_convention_test.rb", "test/unit/xml_hash_test.rb", "test/unit/xml_initialize_test.rb", "test/unit/xml_name_test.rb", "test/unit/xml_namespace_test.rb", "test/unit/xml_object_test.rb", "test/unit/xml_required_test.rb", "test/unit/xml_text_test.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://roxml.rubyforge.org}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{roxml}
  s.rubygems_version = %q{1.3.1.xported}
  s.summary = %q{Ruby Object to XML mapping library}
  s.test_files = ["test/unit/freeze_test.rb", "test/unit/array_test.rb", "test/unit/xml_convention_test.rb", "test/unit/xml_object_test.rb", "test/unit/xml_required_test.rb", "test/unit/xml_bool_test.rb", "test/unit/roxml_test.rb", "test/unit/xml_name_test.rb", "test/unit/xml_construct_test.rb", "test/unit/options_test.rb", "test/unit/string_test.rb", "test/unit/xml_namespace_test.rb", "test/unit/xml_text_test.rb", "test/unit/overriden_output_test.rb", "test/unit/xml_block_test.rb", "test/unit/xml_attribute_test.rb", "test/unit/inheritance_test.rb", "test/unit/xml_initialize_test.rb", "test/unit/xml_hash_test.rb", "test/unit/to_xml_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.1.0"])
      s.add_runtime_dependency(%q<extensions>, [">= 0.6.0"])
      s.add_development_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.1.0"])
      s.add_dependency(%q<extensions>, [">= 0.6.0"])
      s.add_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.1.0"])
    s.add_dependency(%q<extensions>, [">= 0.6.0"])
    s.add_dependency(%q<newgem>, [">= 1.2.3"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
