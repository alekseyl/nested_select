# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "logger" # Fix concurrent-ruby removing logger dependency which Rails itself does not have
require 'active_record'
require 'active_support'
require 'minitest/autorun'
require 'byebug'
require 'stubberry'
require 'rails_sql_prettifier'
require 'amazing_print'
require "nested_select"

require_relative 'helpers/active_record_initializers'

# ActiveRecord::FixtureSet.create_fixtures('test/fixtures', %w[admins avatars users user_profiles items])
# get the idea of what's happening from rails/test_help.rb
ActiveSupport::TestCase.include ActiveRecord::TestDatabases
ActiveSupport::TestCase.include ActiveRecord::TestFixtures

if ActiveSupport::TestCase.respond_to?(:fixture_paths)
  ActiveSupport::TestCase.fixture_paths << "test/fixtures"
else
  ActiveSupport::TestCase.fixture_path = "test/fixtures" # File.expand_path("../test/fixtures", __FILE__)
end
ActiveSupport::TestCase.fixtures :all
module TestCaseHelpers
  def identify(fixture_name)
    ActiveRecord::FixtureSet.identify(fixture_name)
  end
end

ActiveSupport::TestCase.include TestCaseHelpers

def log_ar; ActiveRecord::Base.logger = Logger.new(STDOUT) end

