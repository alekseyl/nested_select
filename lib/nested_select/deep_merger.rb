module NestedSelect
  module DeepMerger

    # {user_profile: [:zip_code]} + {user_profile: [:bio]} -> { user_profile: [:zip_code, :bio] }
    refine Hash do
      def deep_combine(other)
        merge!(other.except(*keys))
        merge!(other.slice(*keys).map{ |key, value| [key, [self[key], value].flatten.deep_combine_elements]}.to_h )
      end
    end

    refine Array do
      def deep_combine_elements
        [*grep_v(Hash), grep(Hash).inject(&:deep_combine)].uniq.compact
      end
    end
  end
end