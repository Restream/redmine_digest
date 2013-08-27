class AddNotifyOptionsToDigestRules < ActiveRecord::Migration
  def change
    add_column :digest_rules, :notify, :string, :default => 'all'
  end
end
