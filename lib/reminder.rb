class Reminder
  class << self
    def process_reminder(msg, user_id, fb_id)
      matched_grps = msg.scan(reminder_pattern).flatten
      time_fig = matched_grps[0].to_i
      details = { user_id: user_id,
                  fb_user_id: fb_id,
                  message: matched_grps[2]
                }
      set_reminder(time_fig, matched_grps[1], details)
    end

    def reminder_pattern
      /remind me in\s(\d+)\s?(min|minute|hr|hour|day|wk|week|month|yr|year)s?\sthat\s((\w+)\sborrowed\s(\d+))/
    end
  end

  private

  def set_reminder(fig, category, details)
    if span = time_span(fig, category)
      ReminderWorker.perform_in(fig.send(span), details)
      "Your reminder has been set. Yippe!"
    else
      "Your reminder can not be more than a year."
    end
  end

  def time_span(fig, span)
    return "years" if (fig == 1) && (span =~ /yr|year/)
    return "months" if (fig < 13) && (span =~ /month/)
    return "weeks" if (fig < 53) && (span =~ /wk|week/)
    return "days" if (fig < 367) && (span =~ /day/)
    return "hours" if (fig < 8785) && (span =~ /hr|hour/)
    "minutes" if (fig < 527041) && (span =~ /min|minute/)
  end
end
