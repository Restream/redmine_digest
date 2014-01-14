class DigestEventFactory
  def self.new_event(event_type, issue_id, created_on, user, journal = nil, journal_detail = nil)
    special_klass = "DigestEvent::#{event_type.to_s.classify}"
    event_klass = special_klass.constantize rescue DigestEvent::Base
    event_klass.new(event_type, issue_id, created_on, user, journal, journal_detail)
  end
end
