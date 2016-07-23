class VerifyController < ApplicationController
  def webhock
    if params["object"] == "page"
      params["entry"].each do |field|
        page_id = field["id"]
        event_time = field["time"]
        field["messaging"].each do |message|
          msg = message["message"]
          return unless msg
          @fb_user_id = get_user(message)
          @user = User.find_or_create_by(facebook_id: @fb_user_id)
          response = parse_message(msg["text"].downcase.strip)
          process_message(@fb_user_id, response)
        end
      end
    end

    head 200
  end

  private

  def parse_message(msg)
    if msg =~ Reminder.reminder_pattern
      { template: 'default', message: Reminder.process_reminder(msg, @user.id, @fb_user_id) } 
    elsif msg == "list debtors"
      { template: 'default', message: list_debtors(@user.debtors) }
    elsif msg =~ /(\w+)\s(refunded|paid)\s(\d+)/
      debtor_name = $1
      amount = $3
      debtor = @user.debtors.find_by(name: debtor_name)
      { template: 'default', message: manage_debt(debtor, amount, debtor_name) }
    elsif msg =~ /^(\w+)\sborrowed\s(\d+)$/
      new_debtor = $1
      amount = $2
      old_debtor = Debtor.find_by(name: new_debtor)
      { template: 'default', message: manage_debtor(old_debtor, new_debtor, amount) }
    elsif msg =~ /remove\s(\w+)/
      debtor_name = $1
      { template: 'default', message: remove_debtor(debtor_name) }
    elsif msg =~ /(view|show)\stransactions(\s--sort)?/
      { template: 'receipt', message: show_transactions($2) }
    else
      { template: 'default', message: list_commands.join("\n") }
    end
  end

  def remove_debtor(debtor_name)
    debtor = Debtor.find_by(name: debtor_name)
    if debtor
      debtor.destroy
      @user.transactions.create({
        description: "You removed #{debtor_name} from your debtors list",
        debtor: debtor_name
      })      
      "#{debtor_name} has been removed"
    else
      "#{debtor_name} is invalid or does not exist"
    end
  end

  def manage_debtor(debtor, new_debtor, amount)
    if debtor
      debtor.amount += amount.to_f
      debtor.save
    else
      debtor = @user.debtors.create(name: new_debtor, amount: amount)
    end
    @user.transactions.create({
      description: "#{debtor.name} borrowed #{amount.to_f}",
      debtor: debtor.name,
      amount: amount.to_f,
      balance: debtor.amount
    })            
    "#{debtor.name} is owing #{debtor.amount}"
  end

  def manage_debt(debtor, amount, debtor_name)
    if debtor && debtor.amount.to_f >= amount.to_f
      debtor.amount -= amount.to_f
      debtor.save
      @user.transactions.create({
        description: "#{debtor.name} refunded #{amount.to_f}",
        debtor: debtor.name,
        amount: amount.to_f,
        balance: debtor.amount
      })      
      "#{debtor.name} debt now #{debtor.amount}"
    else
      "#{debtor_name} does not exist or amount is invalid"
    end
  end

  def list_commands
    [
      "Invalid command: try any of the following",
      "",
      "To add new debtor use this: <name> borrowed <amount>",
      "",
      "To list debtors use this: list debtors",
      "",
      "To remove debtor use this: remove <name>",
      "",
      "To deduct amount from loan use this:: <name> paid || refunded <amount>",
      "",
      "To set reminder for debt use: <remind me in> [time in digit e.g 5] [time category e.g mins, hours, days, weeks etc] <that> [borrower's name] <borrowed> [amount]",
      "",
      "To show all transactions: <show | list> transactions",
      "To show all transactions, sorted by debtor: <show | list> transactions --sort"
    ]
  end

  def list_debtors(debtors)
    return "You don't have any debtor(s)" if debtors.empty?
    debtors.map{|debtor| "#{debtor.name} is owing #{debtor.amount}"}.join("\n")
  end

  def show_transactions(sort)
    puts sort
    return @user.transactions.all.order(:debtor) if sort == ' --sort'
    @user.transactions.all
  end

  def get_user(messaging)
    messaging["sender"]["id"]
  end

  def process_message(user_id, response)
    if response[:template] == 'default'
      message = default_template(response[:message])
    elsif response[:template] == 'receipt'
      message = receipt_template(response[:message])
    end
    make_request(user_id, message)
  end

  def default_template(message)
    { text: message }
  end

  def receipt_template(object)
    {
      attachment:{
        type:"template",
        payload:{
          template_type:"receipt",
          recipient_name: @user.facebook_id.to_s,
          order_number: rand(9999999999),
          currency:"NGN",
          payment_method:"Visa",        
          elements: object.map { |entry| {
            title: entry.debtor,
            subtitle: entry.description,
            price: entry.amount
          }},
          summary:{
            total_cost: @user.debtors.sum(:amount)
          }
        }
      }
    }
  end

  def make_request(user_id, message)
    response = {
      recipient: { id: user_id },
      message: message
    }

    token = ENV["facebook_token"]
    uri = 'https://graph.facebook.com/v2.6/me/messages'
    uri += '?access_token=' + token

    Faraday.new(url: uri).post do |req|
      req.body = response.to_json
      req.headers['Content-Type'] = 'application/json'
    end
    # puts response.inspect
    # render json: { message: response }, status: 200
  end
end
