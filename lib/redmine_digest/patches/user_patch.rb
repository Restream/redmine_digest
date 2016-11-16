require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

module RedmineDigest
  module Patches
    module UserPatch
      extend ActiveSupport::Concern

      included do
        has_many :digest_rules
      end

      def involved_in?(issue)
        issue.author == self ||
          is_or_belongs_to?(issue.assigned_to) ||
          is_or_belongs_to?(issue.assigned_to_was)
      end

      def skip_issue_add_notify?(issue)
        return false if involved_in?(issue) || issue.watched_by?(self)

        # do not send notification if exists at least one
        # rule with digest_only notify option for this event
        digest_rules.active.digest_only.to_a.any? do |rule|
          rule.apply_for_created_issue?(issue)
        end
      end

      def skip_issue_edit_notify?(journal)
        issue = journal.issue
        return false if involved_in?(issue) || issue.watched_by?(self)

        # do not send notification if exists at least one
        # rule with digest_only notify option for this event
        digest_rules.active.digest_only.to_a.any? do |rule|
          rule.apply_for_updated_issue?(journal)
        end
      end
    end
  end
end
