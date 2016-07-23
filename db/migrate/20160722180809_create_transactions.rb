class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.text :description
      t.string :debtor
      t.float :amount, default: 0
      t.float :balance, default: 0
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
