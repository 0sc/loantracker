class VerifyController < ApplicationController
  def webhock
    if params['hub.mode'] == 'subscribe' && params['hub.verify_token'] == 'loan-tracker-tracking'
      render json: params['hub.challenge']
    else
      head 403
    end
  end
end
