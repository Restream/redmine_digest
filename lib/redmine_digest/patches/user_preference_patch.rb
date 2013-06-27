require 'user_preference'

module RedmineDigest::Patches
  module UserPreferencePatch
    extend ActiveSupport::Concern

    def digest_enabled
      self[:digest_enabled]
    end

    def digest_enabled=(val)
      val = 1 if val.is_a? TrueClass
      val = 0 if val.is_a? FalseClass
      self[:digest_enabled] = val
    end

    def digest_enabled?
      digest_enabled.to_i == 1
    end

    def skip_digest_notifications
      self[:skip_digest_notifications]
    end

    def skip_digest_notifications=(val)
      val = 1 if val.is_a? TrueClass
      val = 0 if val.is_a? FalseClass
      self[:skip_digest_notifications] = val
    end

    def skip_digest_notifications?
      skip_digest_notifications.to_i == 1
    end

  end
end

unless UserPreference.included_modules.include?(RedmineDigest::Patches::UserPreferencePatch)
  UserPreference.send :include, RedmineDigest::Patches::UserPreferencePatch
end
