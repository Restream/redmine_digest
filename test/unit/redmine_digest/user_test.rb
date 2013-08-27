require File.expand_path('../../../test_helper', __FILE__)

class RedmineDigest::UserTest < ActiveSupport::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
           :time_entries,
           :watchers

  def setup
    @user = User.find(3)
    @issue = Issue.find(1)
    @journal = Journal.find(1) # issue_id: 1, changed status and done_ratio
  end

  def test_skip_notify_if_option_digest
    create_rule DigestRule::DIGEST_ONLY
    assert_true @user.skip_issue_add_notify?(@issue)
  end

  def test_do_not_skip_notify_if_option_all
    create_rule DigestRule::NOTIFY_AND_DIGEST
    assert_false @user.skip_issue_add_notify?(@issue)
  end

  def test_do_not_skip_notify_if_option_notify
    create_rule DigestRule::NOTIFY_ONLY
    assert_false @user.skip_issue_add_notify?(@issue)
  end

  def test_skip_edit_notify_if_option_digest
    create_rule DigestRule::DIGEST_ONLY
    assert_true @user.skip_issue_edit_notify?(@journal)
  end

  def test_do_not_skip_edit_notify_if_option_all
    create_rule DigestRule::NOTIFY_AND_DIGEST
    assert_false @user.skip_issue_edit_notify?(@journal)
  end

  def test_do_not_skip_edit_notify_if_option_notify
    create_rule DigestRule::NOTIFY_ONLY
    assert_false @user.skip_issue_edit_notify?(@journal)
  end

  def create_rule(notify_option)
    @user.digest_rules.create(
        :name => 'test',
        :notify => notify_option,
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => DigestEvent::TYPES
    )
  end
end
