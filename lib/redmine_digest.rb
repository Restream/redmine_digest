module RedmineDigest
  class DigestError < RuntimeError
  end
end

require_dependency 'redmine_digest/patches/project_patch'
require_dependency 'redmine_digest/patches/user_patch'
require_dependency 'redmine_digest/patches/my_controller_patch'
require_dependency 'redmine_digest/patches/issue_patch'
require_dependency 'redmine_digest/patches/journal_patch'

ActionDispatch::Callbacks.to_prepare do

  unless Project.included_modules.include? RedmineDigest::Patches::ProjectPatch
    Project.send :include, RedmineDigest::Patches::ProjectPatch
  end

  unless User.included_modules.include?(RedmineDigest::Patches::UserPatch)
    User.send :include, RedmineDigest::Patches::UserPatch
  end

  unless MyController.included_modules.include?(RedmineDigest::Patches::MyControllerPatch)
    MyController.send :include, RedmineDigest::Patches::MyControllerPatch
  end

  unless Issue.included_modules.include?(RedmineDigest::Patches::IssuePatch)
    Issue.send :include, RedmineDigest::Patches::IssuePatch
  end

  unless Journal.included_modules.include?(RedmineDigest::Patches::JournalPatch)
    Journal.send :include, RedmineDigest::Patches::JournalPatch
  end

end

