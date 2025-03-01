# TODO describe Branch dedications
module NestedSelect
  module Preloader
    module Branch
      attr_accessor :nested_select_values
      def preloaders_for_reflection(reflection, reflection_records)
        prevent_belongs_to_foreign_key_absence!(reflection)

        super.tap do |ldrs|
          # nested_select_values contains current level selection + nested relation selections
          ldrs.each{ _1.apply_nested_select_values(nested_select_values) } if nested_select_values.present?
        end
      end

      private
      def prevent_belongs_to_foreign_key_absence!(reflection)
        return unless reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)

        # ActiveRecord will not raise in case its missing, so we should prevent silent error here
        if parent.nested_select_values.present? &&
          !parent.nested_select_values.grep_v(Hash)
                 .map(&:to_sym).include?(reflection.foreign_key.to_sym)

          raise ActiveModel::MissingAttributeError, <<~ERR
            Parent reflection #{parent.association} was missing foreign key #{reflection.foreign_key} in nested selection,
            while trying to preload belongs_to reflection named #{reflection.name}.
            Hint: didn't you forgot to add #{reflection.foreign_key} inside #{parent.nested_select_values}?
          ERR
        end
      end
    end
  end
end