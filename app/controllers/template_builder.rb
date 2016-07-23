class TemplateBuilder
    def self.build(type, msg)
        send(type, meg)
    end

    def self.default(msg)
        { text: msg }
    end

    def self.receipt(object, user)
      {
        attachment:{
          type:"template",
          payload:{
            template_type:"receipt",
            recipient_name: user.facebook_id.to_s,
            order_number: rand(9999999999),
            currency:"NGN",
            payment_method:"Not specified",        
            elements: object.map { |entry| {
              title: entry.debtor,
              subtitle: entry.description,
              price: entry.amount
            }
          },
          summary:{
            total_cost: user.debtors.sum(:amount)
          }
        }
      }   
    }
  end
end