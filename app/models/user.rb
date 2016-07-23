class User < ActiveRecord::Base
  has_many :debtors
  has_many :transactions
end
