module NestedSelect
  module Preloader
    module ThroughAssociation
      def through_preloaders
        @through_preloaders ||= ActiveRecord::Associations::Preloader.new(
          records: owners,
          associations: through_reflection.name,
          scope: through_scope,
          associate_by_default: false,
          ).tap { _1.apply_nested_select_values(nested_select_values) }.loaders
      end

      def apply_nested_select_values( partial_select_values )
        return super unless reflection.parent_reflection.is_a?( ActiveRecord::Reflection::HasAndBelongsToManyReflection )

        # when parent reflection is a HasAndBelongsToManyReflection,
        # then we don't need foreign_key to be included, as it does in super
        @nested_select_values = partial_select_values
      end
    end
  end
end

