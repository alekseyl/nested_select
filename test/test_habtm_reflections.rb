# frozen_string_literal: true
require "test_helper"

class TestHabtmReflections < ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  self.use_instantiated_fixtures = true


  test "select allows nesting attribute selection" do
    item = Item.includes(users: [user_profile: :avatars])
               .select("items.*", users: [:id, :name, user_profile: [:id, :bio, avatars: [:img_url]]])
               .find(identify(:mug))

    user = item.users.first
    assert_equal(user.name, "Frodo")
    assert_raises(ActiveModel::MissingAttributeError) { user.membership }
    assert_equal(user.reload.membership, "basic")

    assert_includes(user.user_profile.avatars.map(&:img_url), avatars(:frodo_avatar).img_url)
  end

  test "works fine with inverse_of basic reflection" do
    user = User.includes(user_profile: :avatars)
               .select("users.*", user_profile: [:id, :user_id, avatars: [:id, :user_profile_id]])
               .find(identify(:frodo))

    # NestedSelect::Preloader::Branch#preloaders_for_reflection
    assert_equal(user.user_profile.user.object_id, user.object_id)
    assert_equal(user.user_profile.object_id, user.user_profile.avatars.first.user_profile.object_id)
  end

  test "works fine with through reflection" do
    user = User.includes(:avatars)
               .select("users.*", avatars: [:id, :user_profile_id])
               .find(identify(:frodo))

    assert_raises(ActiveModel::MissingAttributeError) { user.avatars.first.img_url }
    assert_equal(user.avatars, [avatars(:frodo_avatar)])
    assert_equal(user.avatars.first.reload.img_url, "https://api.rubyonrails.org/")
  end

  test "partial selection always includes foreign keys" do
    user = User.includes(user_profile: :avatars)
               .select("users.*", user_profile: [:id, :bio])
               .find(identify(:frodo))

    assert_equal(user.user_profile.user_id, user.id)
  end

  test "partial selection always includes foreign keys also for through reflection bb" do
    user = User.includes(:avatars)
               .select("users.*", avatars: [:id, :img_url])
               .find(identify(:frodo))

    assert_equal(user.avatars, [avatars(:frodo_avatar)])
    assert_not_nil(user.avatars.first.user_profile_id)
  end

end