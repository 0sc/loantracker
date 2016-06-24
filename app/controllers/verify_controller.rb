class VerifyController < ApplicationController
  def webhock
    if params["object"] == "page"
      params["entry"].each do |field|
        page_id = field["id"]
        event_time = field["time"]

        field["messaging"].each do |message|
          msg = message["message"]
          return unless msg

          user_id = get_user(message)
          @user = User.find_or_create_by(facebook_id: user_id)
          response_msg = parse_message(msg["text"])
          process_message(response_msg, user_id)
        end
      end
    end

    head 200
  end

  def parse_message(msg)
    if msg =~ /(\w+)\sborrowed\s(\d+)/
      debtor = $1
      amount = $2
      @user.debtors.create(name: debtor, amount: amount)
      return "success"
    elsif msg == "list debtors"
      return list_debtors(@user.debtors)
    elsif msg =~ /(\w+)\s(refunded|paid)\s(\d+)/
      debtor_name = $1
      amount = $3
      debtor = @user.debtors.find_by(name: debtor_name)
      manage_debt(debtor, amount, debtor_name)
    else
      return "Invalid command: try x borrowed y"
    end
  end

  def manage_debt(debtor, amount, debtor_name)
    puts debtor.amount
    puts amount
    if debtor && debtor.amount >= amount.to_f
      debtor.amount -= amount
      debtor.save
      "#{debtor.name} debt now #{debtor.amount}"
    else
      "#{debtor_name} does not exist or amount is invalid"
    end
  end

  def list_debtors(debtors)
    all_debtors = []
    debtors.each do |debtor|
      all_debtors << "#{debtor.name} is owing #{debtor.amount}"
    end
    all_debtors.join("\n")
  end

  def get_user(messaging)
    return messaging["sender"]["id"]
  end

  def process_message(response_msg, user_id)
    # return "right"
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
