module NestedSelect
  module Preloader
    module Association
      attr_reader :nested_select_values

      def build_scope
        nested_select_values.blank? ? super
          : super.select(*nested_select_values)
      end

      def apply_nested_select_values( partial_select_values )
        @nested_select_values = [*partial_select_values, reflection.foreign_key].uniq
      end
    end
  end
end

