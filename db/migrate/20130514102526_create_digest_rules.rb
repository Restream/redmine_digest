class CreateDigestRules < ActiveRecord::Migration
  def change
    create_table :digest_rules, force: true do |t|
      t.references :user
      t.string :name
      t.integer :position
      t.boolean :active
      t.string :recurrent
      t.string :project_selector
      t.text :project_ids
      t.text :event_ids
      t.timestamps
    end
  end
end
