class CreateDebtors < ActiveRecord::Migration
  def change
    create_table :debtors do |t|
      t.string :name
      t.float :amount
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
