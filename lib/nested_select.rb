# frozen_string_literal: true
require "logger" # Fix concurrent-ruby removing logger dependency which Rails itself does not have
require_relative "nested_select/version"

module NestedSelect
  extend ActiveSupport::Autoload

  autoload :Relation, "nested_select/relation"
  autoload :Preloader, "nested_select/preloader"

  ActiveRecord::Relation.prepend(Relation)
  ActiveRecord::Associations::Preloader.include(Preloader)
  class Error < StandardError; end
  # Your code goes here...
end
