require File.expand_path('../../../test_helper', __FILE__)

class RedmineDigest::DigestTest < ActiveSupport::TestCase
  fixtures :users, :user_preferences, :roles, :projects, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :journals, :journal_details,
           :enabled_modules, :enumerations

  def setup
    @user = User.find(1)
  end

  def test_time_from_daily
    rule = @user.digest_rules.build :recurrent => DigestRule::DAILY
    time_to = Date.new(2013, 05, 16).to_time
    time_from = Date.new(2013, 05, 15).to_time
    digest = RedmineDigest::Digest.new(rule, time_to)
    assert_equal time_from, digest.time_from
  end

  def test_time_from_weekly
    rule = @user.digest_rules.build :recurrent => DigestRule::WEEKLY
    time_to = Date.new(2013, 05, 16).to_time
    time_from = Date.new(2013, 05, 9).to_time
    digest = RedmineDigest::Digest.new(rule, time_to)
    assert_equal time_from, digest.time_from
  end

  def test_time_from_monthly
    rule = @user.digest_rules.build :recurrent => DigestRule::MONTHLY
    time_to = Date.new(2013, 05, 16).to_time
    time_from = Date.new(2013, 04, 16).to_time
    digest = RedmineDigest::Digest.new(rule, time_to)
    assert_equal time_from, digest.time_from
  end

  def test_sorted_digest_issues
    user = User.find(2)
    rule = user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => DigestEvent::TYPES
    )
    time_to = Journal.last.created_on + 1.hour
    digest = RedmineDigest::Digest.new(rule, time_to)
    exp_ids = [1, 2, 4, 6, 7, 8, 11, 12]
    sorted_ids = digest.sorted_digest_issues.values.flatten.map(&:id).sort
    assert_equal exp_ids, sorted_ids
  end

  def test_all_projects
    user = User.find(2)
    rule = user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => DigestEvent::TYPES
    )
    time_to = Journal.last.created_on + 1.hour
    digest = RedmineDigest::Digest.new(rule, time_to)
    exp_ids = [1, 2, 4, 6, 7, 8, 11, 12]
    issue_ids = digest.issues.map(&:id).sort
    assert_equal exp_ids, issue_ids
  end

  def test_selected_projects
    user = User.find(2)
    rule = user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::SELECTED,
        :raw_project_ids => '2,5',
        :event_ids => DigestEvent::TYPES
    )
    time_to = Journal.last.created_on + 1.hour
    digest = RedmineDigest::Digest.new(rule, time_to)
    exp_ids = [4, 6]
    issue_ids = digest.issues.map(&:id).sort
    assert_equal exp_ids, issue_ids
  end

  def test_not_selected_projects
    user = User.find(2)
    rule = user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::NOT_SELECTED,
        :raw_project_ids => '1',
        :event_ids => DigestEvent::TYPES
    )
    time_to = Journal.last.created_on + 1.hour
    digest = RedmineDigest::Digest.new(rule, time_to)
    exp_ids = [4, 6]
    issue_ids = digest.issues.map(&:id).sort
    assert_equal exp_ids, issue_ids
  end

  def test_member_projects
    user = User.find(8)
    rule = user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::MEMBER,
        :event_ids => DigestEvent::TYPES
    )
    time_to = Journal.last.created_on + 1.hour
    digest = RedmineDigest::Digest.new(rule, time_to)
    exp_ids = [4, 6]
    issue_ids = digest.issues.map(&:id).sort
    assert_equal exp_ids, issue_ids
  end

  def test_member_not_selected_projects
    user = User.find(2)
    rule = user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::MEMBER_NOT_SELECTED,
        :raw_project_ids => '5, 2',
        :event_ids => DigestEvent::TYPES
    )
    time_to = Journal.last.created_on + 1.hour
    digest = RedmineDigest::Digest.new(rule, time_to)
    exp_ids = [1, 2, 7, 8, 11, 12]
    issue_ids = digest.issues.map(&:id).sort
    assert_equal exp_ids, issue_ids
  end

  def test_time_zone
    Time.use_zone('UTC') do
      # leave only ane issue at midnight UTC
      Issue.delete_all('id <> 1')
      Issue.find(1).update_attribute :created_on, Date.current.midnight
    end

    issue_ids = get_digest_issues_with_time_zone 'Azores' # UTC -01:00
    assert_equal [], issue_ids, 'Should not see update at midnight UTC'
  end

  def test_time_zone2
    Time.use_zone('UTC') do
      # leave only ane issue at midnight UTC
      Issue.delete_all('id <> 1')
      Issue.find(1).update_attribute :created_on, Date.current.midnight
    end

    issue_ids = get_digest_issues_with_time_zone 'Moscow' # UTC +04:00
    assert_equal [1], issue_ids, 'Should see update at midnight UTC'
  end

  def get_digest_issues_with_time_zone(time_zone)
    user = User.find(2)
    user.pref.time_zone = time_zone
    user.pref.save!
    user = User.find(2) # because time_zone is caching
    ActiveRecord::Base.connection.schema_cache.clear!
    rule = user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::DAILY,
        :project_selector => DigestRule::ALL,
        :event_ids => DigestEvent::TYPES
    )
    digest = RedmineDigest::Digest.new(rule)
    digest.issues.map(&:id)
  end

  def test_digest_projects_count
    user = User.find(2)
    rule = user.digest_rules.create(
        :name => 'test',
        :recurrent => DigestRule::MONTHLY,
        :project_selector => DigestRule::ALL,
        :event_ids => DigestEvent::TYPES
    )
    time_to = Journal.last.created_on + 1.hour
    digest = RedmineDigest::Digest.new(rule, time_to)
    assert_equal 3, digest.projects_count
    assert_equal true, digest.many_projects?
  end
end
