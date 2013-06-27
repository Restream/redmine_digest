require File.expand_path('../../../test_helper', __FILE__)

class RedmineDigest::IssueTest < ActiveSupport::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
           :time_entries

  include Redmine::I18n

  def setup
    @user = User.find(2)
    @user.pref.digest_enabled = true
    @user.pref.skip_digest_notifications = true
    @user.pref.save!
  end

  def test_recipients_should_not_include_users_with_digest
    @user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => [DigestEvent::ISSUE_CREATED]
    )

    issue = Issue.find(1)
    assert_not_include @user.mail, issue.recipients
  end

  def test_watcher_recipients_should_not_include_users_with_digest
    user = User.find(3)
    user.pref.digest_enabled = true
    user.pref.skip_digest_notifications = true
    user.pref.save!
    user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => [DigestEvent::ISSUE_CREATED]
    )

    issue = Issue.find(2)
    assert_not_include user.mail, issue.watcher_recipients
  end

  def test_recipients_should_include_users_skipped_digest_notifications_on_update
    types = DigestEvent::TYPES.dup
    types.delete(DigestEvent::ISSUE_CREATED)
    @user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => types
    ) # issue_ids in digest: [1, 2, 4, 6, 7, 8, 11, 12]

    issue = Issue.find(1)
    assert_include @user.mail, issue.recipients
  end
end
