class DigestEvent::CommentAdded < DigestEvent::Base
  def value
    journal.notes
  end

  def event_summary
    "#{user_stamp}: #{cutted_text(value)}"
  end

  private

  def format_value(val)
    val.nil? ? '-' : cutted_text(val)
  end
end
