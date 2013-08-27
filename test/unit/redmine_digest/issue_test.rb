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
           :time_entries,
           :watchers


  include Redmine::I18n

  # x - doesn't matter
  #
  # #case | skip | in_digest? | assigned_to | watcher? | skip_notification?
  #       |      |            | user?       |          |
  # -----------------------------------------------------------------------
  #   1     x     no            *             *         no
  #   3     on    yes           no            no        yes
  #         on    yes           *             yes       no
  #         on    yes           yes           *         no

  def setup
    @assignee = User.find(2)
    @assignee.mail_notification = 'all'
    @assignee.save!
    @assigned_issue = Issue.find(8)
    @assigned_issue.assigned_to = @assignee
    @assigned_issue.save!

    @watcher = User.find(3)
    @watcher.mail_notification = 'all'
    @watcher.save!
    @watched_issue = Issue.find(2)

    # from project where @assignee and @watcher are members
    @not_involved_issue = Issue.find(1)
    @not_involved_issue.author = User.find(1)
    @not_involved_issue.save!
  end

  def test_case_1_skip_off__with_no_digests
    assert_include @assignee.mail, @assigned_issue.recipients
    assert_include @watcher.mail, @watched_issue.watcher_recipients
    assert_include @assignee.mail, @not_involved_issue.recipients
    assert_include @watcher.mail, @not_involved_issue.recipients
  end

  def test_case_3_skip_on__issue_in_digest
    create_digest_rule(@assignee)
    create_digest_rule(@watcher)
    assert_include @assignee.mail, @assigned_issue.recipients
    assert_include @watcher.mail, @watched_issue.watcher_recipients
    assert_not_include @assignee.mail, @not_involved_issue.recipients
    assert_not_include @watcher.mail, @not_involved_issue.recipients
  end

  def create_digest_rule(user)
    user.digest_rules.create(
        :name => 'test',
        :notify => DigestRule::DIGEST_ONLY,
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => DigestEvent::TYPES
    )
  end
end
