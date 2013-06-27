require File.expand_path('../../../test_helper', __FILE__)

class RedmineDigest::UserPreferenceTest < ActiveSupport::TestCase
  fixtures :users

  def test_set_user_skip_digest_notifications
    user = User.find(1)
    user.pref.attributes = { 'skip_digest_notifications' => '1' }
    user.pref.save!
    user = User.find(1)
    assert_true user.pref.skip_digest_notifications?
  end

  def test_user_skip_digest_notifications_by_default_false
    user = User.find(1)
    assert_false user.pref.skip_digest_notifications?
  end
end
