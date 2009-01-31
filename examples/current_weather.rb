#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '../spec/spec_helper')

class Base
  include ROXML
  xml_convention :dasherize
  xml_namespace 'aws'
end

class WeatherObservation < Base
  xml_name 'ob'
  xml_reader :temperature, :as => Float, :from => 'aws:temp'
  xml_reader :feels_like, :as => Integer
  xml_reader :current_condition #, :attributes => {:icon => String}
end

class Weather < Base
  xml_reader :observations, [WeatherObservation]
end

unless defined?(Spec)
  Weather.from_xml(xml_for('current_weather')).observations.each do |current_weather|
    puts "temperature: #{current_weather.temperature}"
    puts "feels_like: #{current_weather.feels_like}"
    puts "current_condition: #{current_weather.current_condition}"
    puts "current_condition.icon: #{current_weather.current_condition.icon}"
  end
end