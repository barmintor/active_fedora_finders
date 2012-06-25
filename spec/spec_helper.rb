ENV["environment"] ||= 'test'
require "bundler/setup"

if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end

require 'active_record'
#require 'active_record/errors'
require 'active-fedora'
require 'rspec'

require 'support/mock_fedora'
require 'active_fedora_finders'

RSpec.configure do |config|
  config.mock_with :mocha
  config.color_enabled = true
end

def fixture(file)
  File.open(File.join(File.dirname(__FILE__), 'fixtures', file), 'rb')
end