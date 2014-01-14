class DigestEvent::AttachmentAdded < DigestEvent::Base
  def event_summary
    "#{user_stamp}: #{value}"
  end
end
