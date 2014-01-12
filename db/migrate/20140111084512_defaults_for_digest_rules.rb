class DefaultsForDigestRules < ActiveRecord::Migration
  def change
    # description was extracted from "other changes"
    DigestRule.find_each do |rule|
      if rule.event_type_enabled? DigestEvent::OTHER_ATTR_CHANGED
        rule.add_event_type DigestEvent::DESCRIPTION_CHANGED
        rule.save
      end
    end
  end
end
