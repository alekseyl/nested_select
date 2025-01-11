module NestedSelect
  module Preloader
    module Association
      attr_reader :nested_select_values

      def build_scope
        nested_select_values.blank? ? super
          : super.select(*nested_select_values)
      end

      def apply_nested_select_values( partial_select_values )
        foreign_key = reflection.foreign_key if !reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection) &&
          !reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)

        @nested_select_values = [*partial_select_values,*foreign_key].uniq
      end
    end
  end
end

