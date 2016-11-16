require_dependency 'issue'
require 'active_support/concern'

module RedmineDigest
  module Patches
    module IssuePatch
      extend ActiveSupport::Concern

      included do
        alias_method_chain :recipients, :digest_filter
        alias_method_chain :watcher_recipients, :digest_filter
      end

      def recipients_with_digest_filter
        found_mails = recipients_without_digest_filter
        found_users = found_mails.map { |mail| User.find_by_mail(mail) }
        found_users.reject do |found_user|
          found_user.skip_issue_add_notify?(self)
        end.map(&:mail)
      end

      def watcher_recipients_with_digest_filter
        found_mails    = watcher_recipients_without_digest_filter
        found_watchers = found_mails.map { |mail| User.find_by_mail(mail) }
        found_watchers.reject do |found_watcher|
          found_watcher.skip_issue_add_notify?(self)
        end.map(&:mail)
      end
    end
  end
end
