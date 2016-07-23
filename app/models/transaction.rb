class Transaction < ActiveRecord::Base
  belongs_to :user

  def self.save_transaction(user, action, amount, debtor)
    create({
        description: "#{debtor.name} #{action} #{amount.to_f}",
        debtor: debtor.name,
        amount: amount.to_f,
        balance: debtor.amount,
        user: user
      })
  end
end
