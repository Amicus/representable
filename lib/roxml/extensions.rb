require 'rubygems'
require 'active_support'

%w(deprecation array string).each do |file|
  require File.join(File.dirname(__FILE__), 'extensions', file)
end