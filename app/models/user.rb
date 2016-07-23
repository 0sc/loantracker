class User < ActiveRecord::Base
  has_many :debtors
  has_many :transactions


  def manage_debts(name, amount, transaction_type)
    debtor = debtors.find_or_initialize_by(name: name)

    if !(debtor.new_record? || transaction_type == "borrowed")
      if debtor.amount >= amount
        debtor.amount -= amount 
        debtor.save
        Transaction.save_transaction(self, transaction_type, amount, debtor)
        "#{debtor.name}'s debt now remains #{debtor.amount}"
      else 
        "Error: #{name} is owing #{debtor.amount} not #{amount}."
      end
    elsif transaction_type == "borrowed"
      debtor.amount ||= 0
      debtor.amount += amount
      debtor.save
      Transaction.save_transaction(self, transaction_type, amount, debtor)
      "#{name} is owing #{debtor.amount}"
    else
      "Error: #{name} is not one of your debtors."
    end
    
  end
end
