require File.expand_path('../../../test_helper', __FILE__)

class RedmineDigest::UserTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    @user = User.find(2)
    @user.pref.digest_enabled = true
    @user.pref.save!
  end

  def test_user_receive_digest_on_issue_created
    @user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => [DigestEvent::ISSUE_CREATED]
    )

    issue = Issue.find(1)
    assert_true @user.receive_digest_on_issue_created?(issue)
  end

  def test_user_receive_digest_on_issue_updated
    @user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => DigestEvent::TYPES
    )

    journal = Journal.find(1) # issue_id: 1, changed status and done_ratio
    assert_true @user.receive_digest_on_journal_updated?(journal)
  end

end
