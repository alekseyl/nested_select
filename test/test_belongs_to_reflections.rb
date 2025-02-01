# frozen_string_literal: true
require "test_helper"

class TestBelongsToReflections < ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  self.use_instantiated_fixtures = true
  # Avatar -> UserProfile -> User

  test "nested select cant run implicit selection of belongs_to without foreign key" do
    avatar_scope = Avatar.includes(user_profile: :user)
               .select(user_profile: [:bio, { users: [:name] }])

    assert_raises(ActiveModel::MissingAttributeError) do
      avatar_scope.find(identify(:frodo_avatar))
    end
  end

  test "nested select works as expected with explicitly selected foreign_keys" do
    avatar = Avatar.includes(user_profile: :user)
                   .select(user_profile: [:bio, :user_id, { user: [:name] }])
                   .find(identify(:frodo_avatar))

    user = avatar.user_profile.user
    assert_equal(user.name, "Frodo")
    assert_raises(ActiveModel::MissingAttributeError) { user.membership }
    assert_equal(user.reload.membership, "basic")
  end

end