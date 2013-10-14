require 'redmine'

Rails.application.paths["app/overrides"] ||= []
Rails.application.paths["app/overrides"] << File.expand_path("../app/overrides", __FILE__)

ActionDispatch::Callbacks.to_prepare do
  require 'redmine_digest'
end

Redmine::Plugin.register :redmine_digest do
  name        'RedmineDigest plugin'
  description 'Send daily/weekly/monthly digest'
  author      'Danil Tashkinov'
  version     '1.0.5'
  url         'https://github.com/Undev/redmine_digest'

  requires_redmine :version_or_higher => '2.2'
  requires_redmine_plugin :redmine__select2, :version_or_higher => '1.0.1'

  permission :manage_digest_rules, { :digest_rules => [:new, :create, :edit, :update] },
             :public => true,
             :require => :loggedin
end
