module NestedSelect
  module Preloader
    module Association
      attr_reader :nested_select_values

      def build_scope
        nested_select_values.blank? ? super :
          super.select(*nested_select_values.grep_v(Hash).map{_1.try(:to_s) }.uniq)
      end

      def apply_nested_select_values(partial_select_values)
        foreign_key = reflection.foreign_key unless reflection.is_a?(ActiveRecord::Reflection::BelongsToReflection)
        @nested_select_values = [*partial_select_values, *foreign_key, *reflection.klass.primary_key]
        ensure_nesting_selection_integrity!
      end

      def ensure_nesting_selection_integrity!
        single_owner = owners.first
        # do nothing unless not yet loaded
        return unless single_owner.association(reflection.name).loaded?

        single_reflection_record = single_owner.send(reflection.name)
        return if single_reflection_record.blank?

        single_reflection_record = single_reflection_record.first if single_reflection_record.is_a?(Enumerable)

        attributes_loaded = single_reflection_record.attributes.keys.map(&:to_s)
        current_selection = @nested_select_values.grep_v(Hash).map(&:to_s)

        basic_attributes_matched = (attributes_loaded & reflection.klass.column_names).tally ==
                                   (current_selection & reflection.klass.column_names).tally

        # this is not a 100% safe verification, but it will match cases with custom attributes selection for example:
        # "(SELECT COUNT(*) FROM images) as IMG_count" =~ /img_count/
        custom_attributes_matched = (attributes_loaded - reflection.klass.column_names).all? do |loaded_attr|
          (current_selection - reflection.klass.column_names).any? do |upcoming_custom_attr|
            upcoming_custom_attr =~ /#{loaded_attr}/i
          end
        end

        raise ActiveModel::MissingAttributeError, <<~ERR if !basic_attributes_matched || !custom_attributes_matched
          Reflection '#{reflection.name}' already loaded with a different set of basic attributes.
          expected: #{current_selection}, already loaded with: #{attributes_loaded}
          Hint: ensure that you are using same set of attributes for entrance of same relation
                on nesting selection tree including reverse through relations
        ERR
      end
    end
  end
end

