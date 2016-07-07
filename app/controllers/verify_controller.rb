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
          response_msg = parse_message(msg["text"].downcase.strip)
          process_message(@fb_user_id, response_msg)
        end
      end
    end

    head 200
  end

  private

  def parse_message(msg)
    if msg =~ Reminder.reminder_pattern
      Reminder.process_reminder(msg, @user.id, @fb_user_id)
    elsif msg == "list debtors"
      list_debtors(@user.debtors)
    elsif msg =~ /(\w+)\s(refunded|paid)\s(\d+)/
      debtor_name = $1
      amount = $3
      debtor = @user.debtors.find_by(name: debtor_name)
      manage_debt(debtor, amount, debtor_name)
    elsif msg =~ /(\w+)\sborrowed\s(\d+)/
      debtor = $1
      amount = $2
      old_debtor = Debtor.find_by(name: debtor)
      manage_debtor(old_debtor, debtor, amount)
    elsif msg =~ /remove\s(\w+)/
      debtor_name = $1
      remove_debtor(debtor_name)
    else
      list_commands.join("\n")
    end
  end

  def remove_debtor(debtor_name)
    debtor = Debtor.find_by(name: debtor_name)
    if debtor
      debtor.destroy
      "#{debtor_name} has been removed"
    else
      "#{debtor_name} is invalid or does not exist"
    end
  end

  def manage_debtor(old_debtor, debtor, amount)
    if old_debtor
      old_debtor.amount += amount.to_f
      old_debtor.save
      "#{old_debtor.name} is owing #{old_debtor.amount}"
    else
      new_debtor = @user.debtors.create(name: debtor, amount: amount)
      "#{new_debtor.name} is owing #{new_debtor.amount}"
    end
  end

  def manage_debt(debtor, amount, debtor_name)
    if debtor && debtor.amount.to_i >= amount.to_i
      debtor.amount -= amount.to_f
      debtor.save
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
      "To set reminder for debt use: <remind me in> [time in digit e.g 5] [time category e.g mins, hours, days, weeks etc] <that> [borrower's name] <borrowed> [amount]"
    ]
  end

  def list_debtors(debtors)
    return "You don't have any debtor(s)" if debtors.empty?
    debtors.map{|debtor| "#{debtor.name} is owing #{debtor.amount}"}.join("\n")
  end

  def get_user(messaging)
    messaging["sender"]["id"]
  end

  def process_message(user_id, response_msg)
    make_request(user_id, response_msg)
  end

  def make_request(user_id, message)
    message = {
      recipient: { id: user_id },
      message: { text: message }
    }
    token = ENV["facebook_token"]
    uri = 'https://graph.facebook.com/v2.6/me/messages'
    uri += '?access_token=' + token

    Faraday.new(url: uri).post do |req|
      req.body = message.to_json
      req.headers['Content-Type'] = 'application/json'
    end
  end
end
