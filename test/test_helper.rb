# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

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

ActiveSupport::TestCase.fixture_paths << "test/fixtures"
ActiveSupport::TestCase.fixtures :all
module TestCaseHelpers
  def identify(fixture_name)
    ActiveRecord::FixtureSet.identify(fixture_name)
  end
end

ActiveSupport::TestCase.include TestCaseHelpers

def log_ar; ActiveRecord::Base.logger = Logger.new(STDOUT) end

