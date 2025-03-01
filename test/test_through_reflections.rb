# frozen_string_literal: true
require "test_helper"

class TestThroughReflections < ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  self.use_instantiated_fixtures = true

  test "will raise attribute error if nesting selection branches differ" do
    scope = User.includes(:through_avatar_images, :avatars)
                .select(avatars: [:img_url, { user_profile: [:zip_code] }],
                        through_avatar_images: [avatars: [:created_at, { user_profile: [:bio] }]])

    assert_raises(ActiveModel::MissingAttributeError) { scope.find(identify(:frodo)) }
  end

  test "will not raise an error when nested selection matches on different branches" do
    scope = User.includes(:avatars, :through_avatar_images)
                .select(avatars: [:img_url, { user_profile: [:zip_code] }],
                       through_avatar_images: [avatars: [:img_url, { user_profile: [:zip_code] }]])

    assert_nothing_raised { scope.find(identify(:frodo)) }
  end

  test "allows intermediate records of through relations to be partially instantiated" do
    user = User.includes(:through_avatar_images)
               .select(through_avatar_images: [avatars: [:img_url, { user_profile: [:zip_code] }]])
               .find(identify(:frodo))

    img = user.through_avatar_images.first
    assert_raises(ActiveModel::MissingAttributeError) { img.owner.created_at }
    assert_nothing_raised { img.owner.img_url }

    assert_raises(ActiveModel::MissingAttributeError) { img.owner.user_profile.bio }
    assert_nothing_raised {  img.owner.user_profile.zip_code }
  end

  test "allows partial selection both way usual and reverse (=through)" do
    user = User.includes(avatars: :images)
               .select(avatars: [:img_url, { user_profile: [:zip_code] }, { images: [:thumb] }])
               .find(identify(:frodo))

    ava = user.avatars.first
    assert_raises(ActiveModel::MissingAttributeError) { ava.created_at }
    assert_nothing_raised { ava.img_url }

    assert_raises(ActiveModel::MissingAttributeError) { ava.user_profile.bio }
    assert_nothing_raised { ava.user_profile.zip_code }

    assert_raises(ActiveModel::MissingAttributeError) { ava.images.first.created_at }
    assert_nothing_raised { ava.images.first.thumb }
  end

  test "allows partial selection both way usual and reverse (=through) bb" do
    user = User.includes(:through_avatar_images)
               .select(through_avatar_images: [:thumb, avatars: [user_profile: [:id]]])
               .find(identify(:frodo))

    assert_equal(user.through_avatar_images.map(&:id), [identify(:avatar_frodo_image)])
    assert_equal(user.through_avatar_images.map(&:thumb), [images(:avatar_frodo_image).thumb])
    assert_raises(ActiveModel::MissingAttributeError) { user.through_avatar_images.map(&:created_at) }
  end

  test "will load everything if only nested selections mentioned" do
    user = User.includes(:through_avatar_images)
               .select(through_avatar_images: [avatars: [user_profile: [:id]]])
               .find(identify(:frodo))

    assert_equal(user.through_avatar_images.map(&:id), [identify(:avatar_frodo_image)])
    assert_equal(user.through_avatar_images.map(&:thumb), [images(:avatar_frodo_image).thumb])
    assert_nothing_raised { user.through_avatar_images.map(&:created_at) }
  end
end
