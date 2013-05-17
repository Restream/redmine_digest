class DigestIssue < Hashie::Dash
  property :id, :required => true
  property :subject, :required => true
  property :project_name

  property :last_updated_on
  property :status_id

  property :is_new, :default => false
  property :events, :default => {}

  def last_event_value(event_type)
    events[event_type].last.value
  end

  def events_summary(event_type)
    events[event_type].map(&:event_summary).join("  \n")
  end

  def initialize(*args)
    super
    DigestEvent::TYPES.each { |t| events[t] = [] }
  end
end
