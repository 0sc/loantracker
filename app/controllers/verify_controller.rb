class VerifyController < ApplicationController
  def webhock
    if params["object"] == "page"
      params["entry"].each do |field|
        page_id = field["id"]
        event_time = field["time"]

        field["messaging"].each do |message|
          process_message(message)
        end
      end
    end

    head 200
  end

  def process_message(message)
    msg = message["message"]
    return unless msg
    
    user_id = get_user(message)
    process_message(user_id)
  end

  def get_user(messaging)
    return messaging["sender"]["id"]
  end

  def get_message(messaging)
    "working as expected"
    # return messaging["message"]["text"]
  end

  def process_message(user_id, message)
    # return "right"
    make_request(user_id, "working as expected #{@user_id}")
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
