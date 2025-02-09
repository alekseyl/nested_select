module NestedSelect
  module Preloader
    extend ActiveSupport::Autoload
    extend ActiveSupport::Concern

    autoload :Branch, "nested_select/preloader/branch"
    autoload :ThroughAssociation, "nested_select/preloader/through_association"
    autoload :Association, "nested_select/preloader/association"

    included do
      ActiveRecord::Associations::Preloader::Branch.prepend(Branch)
      ActiveRecord::Associations::Preloader::ThroughAssociation.prepend(ThroughAssociation)
      ActiveRecord::Associations::Preloader::Association.prepend(Association)
    end

    # first one will start from the roots [included_1: [{}], included_2: [{}] ]
    def apply_nested_select_values(nested_select_values)
      distribute_nested_select_over_loading_tree(@tree, nested_select_values)
    end

    def distribute_nested_select_over_loading_tree(sub_tree, nested_select_values)
      #  nested_select_values = [:id, :title, comments: [:id, :body], cover: [:id, img: [:url]]]
      return if nested_select_values.blank?

      sub_tree.nested_select_values = [*nested_select_values.grep_v(Hash)]
      # sub_nested_select_values = { comments: [:id, :body], cover: [:id, img: [:url]] }
      sub_nested_select_values = nested_select_values.grep(Hash).inject({}, &:merge)&.symbolize_keys

      # it could be a case when selection tree is not that deep than Branch tree.
      return if sub_nested_select_values.blank?

      # its possible to subselect in reverse direction for through relation's
      # in that case includes are implicit, but we need to add that reverse tree into nested select
      reverse_nested_selections = sub_nested_select_values.except(*sub_tree.children.map(&:association))
      # this is for reverse selection of through models
      sub_tree.nested_select_values << reverse_nested_selections if reverse_nested_selections.present?

      sub_tree.children.each do |chld_brnch|
        distribute_nested_select_over_loading_tree(chld_brnch, sub_nested_select_values[chld_brnch.association])
      end
    end
  end
end