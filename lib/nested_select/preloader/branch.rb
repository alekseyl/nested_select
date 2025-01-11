# TODO describe Branch dedications
module NestedSelect
  module Preloader
    module Branch
      attr_accessor :nested_select_values
      def preloaders_for_reflection(reflection, reflection_records)
        super.tap do |ldrs|
          ldrs.each{ _1.apply_nested_select_values(nested_select_values) } if nested_select_values.present?
        end
      end

    end
  end
end