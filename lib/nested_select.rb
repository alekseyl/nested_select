# frozen_string_literal: true

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
