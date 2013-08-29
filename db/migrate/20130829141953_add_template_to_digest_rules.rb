class AddTemplateToDigestRules < ActiveRecord::Migration
  def change
    add_column :digest_rules, :template, :string, :default => 'short'
  end
end
