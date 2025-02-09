# frozen_string_literal: true
require_relative "deep_merger"

module NestedSelect
  module Relation
    using ::NestedSelect::DeepMerger

    attr_accessor :nested_select_values
    def select(*fields)
      # {user_profile: [:zip_code]} + {user_profile: [:bio]} -> { user_profile: [:zip_code, :bio] }
      @nested_select_values = [*@nested_select_values, *fields.grep(Hash)].deep_combine_elements
      # returning self means -- there was only nesting selection,
      # and we should not interfere with default selection
      fields.grep_v(Hash).present? ? super(*fields.grep_v(Hash)) : self
    end

    # # when nested_select interferes the 'through' selection, its doing this in reverse
    # # in this case the first one preload wins a selection scope,
    # # so we need to make them all the same across all selection trees
    # # ( except for the cases when traversing ends up in same place using different path,
    # # this case is out of the normal sense )
    # def combine_reverse_selection_sub_trees
    #   @nested_select_values.permutation.each do |left, right|
    #
    #   end
    # end

    def preload_associations(records) # :nodoc:
      preload = preload_values
      preload += includes_values unless eager_loading?
      scope = strict_loading_value ? StrictLoadingScope : nil
      preload.each do |associations|
        ActiveRecord::Associations::Preloader.new(records:, associations:, scope:)
          .tap{_1.apply_nested_select_values(nested_select_values) } # <-- Patching code
          .call
      end
    end
  end

end
