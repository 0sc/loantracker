class Debtor < ActiveRecord::Base
  belongs_to :user

  after_destroy :record_transaction

  def record_transaction
    user.transactions.create({
        description: "You removed #{name} from your debtors list",
        debtor: name
      })
  end
end
