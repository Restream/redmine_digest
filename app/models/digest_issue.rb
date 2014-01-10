class DigestIssue < Hashie::Dash
  property :id, :required => true
  property :subject, :required => true
  property :project_id
  property :project_name

  property :created_on
  property :last_updated_on
  property :status_id

  property :is_new, :default => false
  property :events

  property :priority

  def last_event_value(event_type)
    events[event_type].last.value
  end

  def events_summary(event_type)
    result = [I18n.t(event_type, :scope => 'event_types')]
    result += events[event_type].map(&:event_summary)
    result.join("  \n")
  end

  def initialize(*args)
    super
    self.events = {}
    DigestEvent::TYPES.each { |t| self.events[t] = [] }
  end

  def any_events?
    event_types.any?
  end

  def any_changes_events?
    changes_event_types.any?
  end

  def new_issue?
    event_types.include?(DigestEvent::ISSUE_CREATED)
  end

  def event_types
    events.values.flatten.compact.map(&:event_type).uniq
  end

  def changes_event_types
    event_types.reject { |event_type| event_type == DigestEvent::ISSUE_CREATED }
  end

  def sort_key
    (priority.try(:position) || 0) * 1000 + uniq_events.count
  end

  def uniq_events
    events.values.flatten.compact.uniq
  end

  def changes
    uniq_events.find_all { |event| event.event_type != DigestEvent::ISSUE_CREATED }
  end
end
