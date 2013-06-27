require 'project'
require 'principal'
require 'user'

module RedmineDigest
  module Patches
    module UserPatch
      extend ActiveSupport::Concern

      included do
        has_many :digest_rules
      end

      def receive_digest_on_issue_created?(issue)
        return false unless pref.digest_enabled?
        digest_rules.inject(false) do |res, rule|
          res || rule.include_issue_on_create?(issue)
        end
      end

      def receive_digest_on_journal_updated?(journal)
        return false unless pref.digest_enabled?
        digest_rules.inject(false) do |res, rule|
          res || rule.include_journal_on_update?(journal)
        end
      end
    end
  end
end

unless User.included_modules.include?(RedmineDigest::Patches::UserPatch)
  User.send :include, RedmineDigest::Patches::UserPatch
end
