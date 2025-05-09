module NestedSelect
  module Preloader
    module ThroughAssociation
      def through_preloaders
        @through_preloaders ||= ActiveRecord::Associations::Preloader.new(
          records: owners,
          associations: through_reflection.name,
          scope: through_scope,
          associate_by_default: false,
          ).tap do
          _1.apply_nested_select_values(nested_select_values&.grep(Hash))
        end.loaders
      end

      def reflection_relation_keys_attributes
        foreign_key = reflection.foreign_key unless reflection.parent_reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
        [*foreign_key, *reflection.klass.primary_key].map(&:to_s)
      end

    end
  end
end

