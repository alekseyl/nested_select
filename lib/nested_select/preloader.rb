module NestedSelect
  module Preloader
    extend ActiveSupport::Autoload
    extend ActiveSupport::Concern

    autoload :Branch, "brest/nested_select/preloader/branch"
    autoload :ThroughAssociation, "brest/nested_select/preloader/through_association"
    autoload :Association, "brest/nested_select/preloader/association"

    included do
      ActiveRecord::Associations::Preloader::Branch.prepend(Branch)
      ActiveRecord::Associations::Preloader::ThroughAssociation.prepend( ThroughAssociation )
      ActiveRecord::Associations::Preloader::Association.prepend( Association )
    end
    def apply_nested_select_values(nested_select_values)
      distribute_nested_select_over_loading_tree(@tree, nested_select_values)
    end

    def distribute_nested_select_over_loading_tree(sub_tree, nested_select_values)
      #  nested_select_values = [:id, :title, comments: [:id, :body], cover: [:id, img: [:url]]]
      return if nested_select_values.blank?

      sub_tree.nested_select_values = nested_select_values.grep_v(Hash)
      # sub_nested_select_values = { comments: [:id, :body], cover: [:id, img: [:url]] }
      sub_nested_select_values = nested_select_values.grep(Hash).inject(&:merge)&.symbolize_keys
      # it could be a case when selection tree is not that deep than Branch tree.
      return if sub_nested_select_values.blank?

      sub_tree.children.each do
        distribute_nested_select_over_loading_tree( _1, sub_nested_select_values[_1.association])
      end
    end
  end
end