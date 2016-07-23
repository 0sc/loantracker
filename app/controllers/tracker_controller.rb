class TrackerController < ApplicationController
  def verify
    if (params['hub.mode'] === 'subscribe' && params['hub.verify_token'] === "VALIDATION_TOKEN") 
      render json: params['hub.challenge']
    else 
      head 403
    end
  end

  def callback
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
          make_request(@fb_user_id, response)
        end
      end
    end

    head 200
  end

  private

  def parse_message(msg)
    if msg =~ Reminder.reminder_pattern
      TemplateBuilder.default(Reminder.process_reminder(msg, @user.id, @fb_user_id))
    elsif msg == "list debtors"
      TemplateBuilder.default(list_debtors(@user.debtors))
    elsif msg =~ /(\w+)\s(refunded|paid|borrowed)\s(\d+)/
      debtor_name = $1
      type = $2
      amount = $3
      msg = @user.manage_debts(debtor_name, amount.to_f, type)
      TemplateBuilder.default(msg)
    elsif msg =~ /remove\s(\w+)/
      debtor_name = $1
      TemplateBuilder.default(remove_debtor(debtor_name))
    elsif msg =~ /(view|show)\stransactions(\s--sort)?/
      transactions = show_transactions($2)
      transactions.empty? ? TemplateBuilder.default("Your account is still green 😅") : TemplateBuilder.receipt(transactions, @user)
    else
      TemplateBuilder.default(list_commands.join("\n"))
    end
  end

  def remove_debtor(debtor_name)
    debtor = @user.debtors.find_by(name: debtor_name)
    if debtor
      debtor.destroy    
      "#{debtor_name} has been removed"
    else
      "#{debtor_name} is invalid or does not exist"
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
    transc = @user.transactions
    transc = transc.order(:debtor) if sort == ' --sort'
    transc.all
  end

  def get_user(messaging)
    messaging["sender"]["id"]
  end

  def make_request(user_id, message)
    response = {
      recipient: { id: user_id },
      message: message
    }

    token = ENV["facebook_token"]
    uri = 'https://graph.facebook.com/v2.6/me/messages'
    uri += '?access_token=' + token

    stat = Faraday.new(url: uri).post do |req|
      req.body = response.to_json
      req.headers['Content-Type'] = 'application/json'
    end

    # puts stat
    # render json: { message: response }, status: 200
  end
end
