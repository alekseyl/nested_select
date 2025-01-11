# frozen_string_literal: true

module NestedSelect
  module Relation

    attr_accessor :nested_select_values
    def select(*fields)
      @nested_select_values = fields.grep(Hash)
      super(*fields.grep_v(Hash))
    end

    def preload_associations(records) # :nodoc:
      preload = preload_values
      preload += includes_values unless eager_loading?
      scope = strict_loading_value ? StrictLoadingScope : nil
      preload.each do |associations|
        ActiveRecord::Associations::Preloader.new(records:, associations:, scope:)
                                             .tap{ _1.apply_nested_select_values(nested_select_values) } # <-- Patching code
                                             .call
      end
    end
  end

end
