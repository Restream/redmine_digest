require 'journal'

module RedmineDigest
  module Patches
    module JournalPatch
      extend ActiveSupport::Concern

      included do
        alias_method_chain :recipients, :digest_filter
        alias_method_chain :watcher_recipients, :digest_filter
      end

      def recipients_with_digest_filter
        found_mails = recipients_without_digest_filter
        found_users = found_mails.map { |mail| User.find_by_mail(mail) }
        found_users.reject do |found_user|
          found_user.pref.skip_digest_notifications? &&
              !found_user.involved_in?(issue) &&
              found_user.receive_digest_on_journal_updated?(self)
        end.map(&:mail)
      end

      def watcher_recipients_with_digest_filter
        found_mails = watcher_recipients_without_digest_filter
        found_watchers = found_mails.map { |mail| User.find_by_mail(mail) }
        found_watchers.reject do |found_watcher|
          found_watcher.pref.skip_digest_notifications? &&
              !issue.watched_by?(found_watcher) &&
              found_watcher.receive_digest_on_journal_updated?(self)
        end.map(&:mail)
      end
    end
  end
end

unless Journal.included_modules.include?(RedmineDigest::Patches::JournalPatch)
  Journal.send :include, RedmineDigest::Patches::JournalPatch
end
