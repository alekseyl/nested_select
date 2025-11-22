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

    # this is copy of the original ActiveRecord::Relation#preload_associations method
    # the only patching I' doing -- streaming down nested_select_values over the preloading trees
    def preload_associations(records) # :nodoc:
      preload = preload_values
      preload += includes_values unless eager_loading?
      scope = strict_loading_value ? StrictLoadingScope : nil
      preload.each do |associations|
        ActiveRecord::Associations::Preloader.new(records:, associations:, scope:)
          .tap do# <-- Patching code goes here
            # at this moment nested_select_values will have a structure of an array of one hash element,
            # with multiple keys matching those in associations, so we need to separate them per branch
            if nested_select_values.present?
              # associations will have a structure of either tree like hash or str/sym
              # Ex: includes(:relation1, relation2: :nested_relation)
              # associations will be either :relation1 or { relation2: :nested_relation }
              root_association_name = (associations.try(:keys) || associations.try(:to_sym) || associations)
              # nested_select_values, after deep_combine_elements
              # will have structure of an array of single element at this moment:
              # [{relation1: [columns..], relation2: [columns, nested_relation: [columns]] }]
              # so we need to populate nested_select_values over associations branch
              _1.apply_nested_select_values([nested_select_values.first.slice(*root_association_name)])
            end
        end.call
      end
    end
  end

end


# ActiveRecord::Associations::Preloader.new(records:, associations:, scope:)
