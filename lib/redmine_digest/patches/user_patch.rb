module RedmineDigest
  module Patches
    module UserPatch
      extend ActiveSupport::Concern

      included do
        has_many :digest_rules
      end
    end
  end
end

unless User.included_modules.include?(RedmineDigest::Patches::UserPatch)
  User.send :include, RedmineDigest::Patches::UserPatch
end
