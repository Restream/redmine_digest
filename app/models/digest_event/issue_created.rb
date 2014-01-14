class DigestEvent::IssueCreated < DigestEvent::Base
  def event_summary
    user_stamp
  end
end
