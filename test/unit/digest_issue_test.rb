require File.expand_path('../../test_helper', __FILE__)

class DigestIssueTest < ActiveSupport::TestCase
  fixtures :users, :user_preferences, :roles, :projects, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :journals, :journal_details,
           :enabled_modules

  def setup
    @user = User.find(2)
    rule = @user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => DigestEvent::TYPES
    )
    time_to = Journal.last.created_on + 1.hour
    @digest = RedmineDigest::Digest.new(rule, time_to)
    # issues: [1, 2, 4, 6, 7, 8, 11, 12]
    @digest_issue = @digest.issues.detect { |issue| issue.id == 1 }
  end

  def test_changes
    changes = @digest_issue.changes
    assert_equal 4, changes.count
  end
end
