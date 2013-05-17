require File.expand_path('../../../test_helper', __FILE__)

class RedmineDigest::DigestTest < ActiveSupport::TestCase

  def test_date_from_daily
    rule = DigestRule.new :recurrent => DigestRule::DAILY
    date_to = Date.new 2013, 05, 16
    date_from = Date.new 2013, 05, 15
    digest = RedmineDigest::Digest.new(rule, date_to)
    assert_equal date_from, digest.date_from
  end

  def test_date_from_weekly
    rule = DigestRule.new :recurrent => DigestRule::WEEKLY
    date_to = Date.new 2013, 05, 16
    date_from = Date.new 2013, 05, 9
    digest = RedmineDigest::Digest.new(rule, date_to)
    assert_equal date_from, digest.date_from
  end

  def test_date_from_monthly
    rule = DigestRule.new :recurrent => DigestRule::MONTHLY
    date_to = Date.new 2013, 05, 16
    date_from = Date.new 2013, 04, 16
    digest = RedmineDigest::Digest.new(rule, date_to)
    assert_equal date_from, digest.date_from
  end

end
