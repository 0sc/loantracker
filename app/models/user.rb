class User < ActiveRecord::Base
  has_many :debtors
end
