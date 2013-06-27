module RedmineDigest
  class DigestError < RuntimeError
  end
end

require 'redmine_digest/patches/user_patch'
require 'redmine_digest/patches/my_controller_patch'
require 'redmine_digest/patches/user_preference_patch'
require 'redmine_digest/patches/issue_patch'
require 'redmine_digest/patches/journal_patch'
