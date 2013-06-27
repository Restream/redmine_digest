require File.expand_path('../../../test_helper', __FILE__)

class RedmineDigest::JournalTest < ActiveSupport::TestCase
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

  def test_recipients_should_not_include_users_with_digest
    user = User.find(3)
    user.pref.digest_enabled = true
    user.pref.skip_digest_notifications = false
    user.pref.save!
    user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::SELECTED,
        :raw_project_ids => '1',
        :event_ids => DigestEvent::TYPES
    )
    journal = Journal.find(1) # issue_id: 1, changed status and done_ratio

    assert_include user.mail, journal.recipients

    user.pref.skip_digest_notifications = true
    user.pref.save!

    assert_not_include user.mail, journal.recipients
  end

  def test_watcher_recipients_should_not_include_users_with_digest
    user = User.find(3)
    user.pref.digest_enabled = true
    user.pref.skip_digest_notifications = false
    user.pref.save!
    user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::SELECTED,
        :raw_project_ids => '1',
        :event_ids => DigestEvent::TYPES
    )
    journal = Journal.find(3) # issue_id: 1, changed status and done_ratio

    assert_include user.mail, journal.watcher_recipients

    user.pref.skip_digest_notifications = true
    user.pref.save!

    assert_not_include user.mail, journal.watcher_recipients
  end

end
