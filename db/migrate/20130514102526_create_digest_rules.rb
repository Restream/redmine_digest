class CreateDigestRules < ActiveRecord::Migration
  def change
    create_table :digest_rules, :force => true do |t|
      t.references :user
      t.string :name
      t.integer :position
      t.boolean :active
      t.integer :recurrent
      t.string :project_selector
      t.text :projects
      t.text :events
      t.timestamps
    end
  end
end
