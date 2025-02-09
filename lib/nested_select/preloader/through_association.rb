module NestedSelect
  module Preloader
    module ThroughAssociation
      # this preloader root will preload intermediate records, so here we should apply 'through'
      # selection limitation AS A BASIC nested selection and it wuold be either __minimize_through_selection sym OR
      # nested_selection tree
      # def source_preloaders
      #   @source_preloaders ||= ActiveRecord::Associations::Preloader.new(
      #     records: middle_records,
      #     associations: source_reflection.name,
      #     scope: scope,
      #     associate_by_default: false
      #   ).tap {
      #     byebug
      #     _1.apply_nested_select_values([*@limit_through_selection])
      #   }.loaders
      # end
      def through_preloaders
        @through_preloaders ||= ActiveRecord::Associations::Preloader.new(
          records: owners,
          associations: through_reflection.name,
          scope: through_scope,
          associate_by_default: false,
          ).tap do
          _1.apply_nested_select_values(nested_select_values.grep(Hash))
        end.loaders
      end

      # def through_scope
      #   if @limit_through_selection.present?
      #     # through_selection is either __minimize_through_selection symbol, or an array
      #     through_selection = [*@limit_through_selection]
      #     through_selection = [*through_selection.grep_v(Hash),
      #                          *through_selection.grep(Hash).first&.dig(through_reflection.source_reflection_name)]
      #     through_selection << through_reflection.foreign_key
      #     through_selection << through_reflection.klass.primary_key
      #     super.select(through_selection)
      #   else
      #     super
      #   end
      # end

      # def through_scope
      #   if @limit_through_selection.present?
      #     super.select(through_reflection.foreign_key.to_sym, through_reflection.klass.primary_key.to_sym)
      #   else
      #     super
      #   end
      # end
      # def through_selection_nesting
      #   return if @limit_through_selection.blank?
      #   through_limit_selection = [through_reflection.foreign_key.to_sym, through_reflection.klass.primary_key.to_sym]
      #   through_limit_selection << :__minimize_through_selection if through_reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)
      #   through_limit_selection
      # end

      def apply_nested_select_values(partial_select_values)

        if reflection.parent_reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
          # when parent reflection is a HasAndBelongsToManyReflection,
          # then we don't need foreign_key to be included, as it does in super
          @nested_select_values = partial_select_values
        else
          @limit_through_selection = partial_select_values.delete(:__minimize_through_selection)
          super(partial_select_values)
        end
      end
      # def exract_through_selections(partial_select_values)
      #   # __minimize_through_selection: [ :user_id, user_profile: [] ]
      #   # there should not be more than one such limitation definition
      #   through_selection_rules, cleaned_partial_select_values = partial_select_values&.partition do
      #     _1 == :__minimize_through_selection || _1.is_a?(Hash) && _1[:__minimize_through_selection].present?
      #   end
      #   @limit_through_selection = through_selection_rules.map do
      #     _1.is_a?(Hash) && _1[:__minimize_through_selection] || _1
      #   end.first
      #
      #   byebug
      #   cleaned_partial_select_values
      # end

    end
  end
end

