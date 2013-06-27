require 'my_controller'

module RedmineDigest
  module Patches
    module MyControllerPatch
      extend ActiveSupport::Concern

      included do
        private :toggle_digest_rules
        before_filter :toggle_digest_rules, :only => [:account], :if => -> { request.post? }
      end

      def toggle_digest_rules
        digest_rules = params.delete :digest_rules
        if digest_rules
          active_ids = digest_rules[:active_ids]
          User.current.digest_rules.each do |digest_rule|
            digest_rule.active = active_ids.include? digest_rule.id.to_s
            digest_rule.save
          end
        end
        true
      end

    end
  end
end

unless MyController.included_modules.include?(RedmineDigest::Patches::MyControllerPatch)
  MyController.send :include, RedmineDigest::Patches::MyControllerPatch
end
