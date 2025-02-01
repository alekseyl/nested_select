# frozen_string_literal: true
require "test_helper"

class TestNestedSelect < ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  self.use_instantiated_fixtures = true

  test "select allows nesting attribute selection" do
    item = Item.includes(users: { user_profile: :avatars })
               .select(users: [:id, :name, { user_profile: [:id, :bio, { avatars: [:img_url] }] }])
               .find(identify(:mug))

    user = item.users.first
    assert_equal(user.name, "Frodo")
    assert_raises(ActiveModel::MissingAttributeError) { user.membership }
    assert_equal(user.reload.membership, "basic")

    assert_includes(user.user_profile.avatars.map(&:img_url), avatars(:frodo_avatar).img_url)
  end

  test "works fine with inverse_of basic reflection" do
    user = User.includes(user_profile: :avatars)
               .select("users.*", user_profile: [:id, :user_id, {avatars: [:id, :user_profile_id]}])
               .find(identify(:frodo))

    # NestedSelect::Preloader::Branch#preloaders_for_reflection
    assert_equal(user.user_profile.user.object_id, user.object_id)
    assert_equal(user.user_profile.object_id, user.user_profile.avatars.first.user_profile.object_id)
  end

  test 'nested select will merge nested selection scopes correctly' do
    scope = User.includes(user_profile: :avatars).select(user_profile: [:zip_code])
    scope = scope.select(user_profile: [:bio, { avatars: [:id] }])
    assert_equal(scope.nested_select_values[0][:user_profile].tally, [:bio, :zip_code, { avatars: [:id] }].tally )

    scope = scope.select(user_profile: { avatars: [:img_url] })
    assert_equal(scope.nested_select_values[0][:user_profile].grep_v(Hash).sort, [:bio, :zip_code])
    assert_equal(scope.nested_select_values[0][:user_profile].grep(Hash)[0], { avatars: [:id, :img_url] })
  end

  test "nested select will not apply any selection to basic relation unless defined explicitly" do
    user = User.includes(:user_profile).select(user_profile: [:id, :bio]).find(identify(:frodo))

    assert_nothing_raised { user.name }
  end

  test "nested select will not apply any selection to nested relations unless defined explicitly" do
    user = User.includes(user_profile: :avatars)
               .select(user_profile: [avatars: [:img_url]])
               .find(identify(:frodo))

    assert_nothing_raised { user.user_profile.bio }
    assert_nothing_raised { user.user_profile.avatars.first.img_url }
    assert_raises(ActiveModel::MissingAttributeError) { user.user_profile.avatars.first.created_at }
  end

  test "nested custom attribute in a nested selection" do
    user = User.includes(:user_profile).select(
      user_profile: [:id, "(SELECT COUNT(*) FROM avatars WHERE user_profiles.id = avatars.user_profile_id) as avs_count"]
    ).find(identify(:sauron))

    assert_equal(user.user_profile.avs_count, 2)
  end
end
