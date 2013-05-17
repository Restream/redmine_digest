class DigestEvent
  STATUS_CHANGED    = 'status_changed'
  PERCENT_CHANGED   = 'percent_changed'
  ASSIGNEE_CHANGED  = 'assignee_changed'
  VERSION_CHANGED   = 'version_changed'
  PROJECT_CHANGED   = 'project_changed'
  COMMENT_ADDED     = 'comment_added'
  ISSUE_CREATED     = 'issue_created'

  TYPES = [STATUS_CHANGED, PERCENT_CHANGED, ASSIGNEE_CHANGED, VERSION_CHANGED,
           PROJECT_CHANGED, COMMENT_ADDED, ISSUE_CREATED]

  PROP_KEYS = {
      STATUS_CHANGED    => 'status_id',
      PERCENT_CHANGED   => 'done_ratio',
      ASSIGNEE_CHANGED  => 'assigned_to_id',
      VERSION_CHANGED   => 'fixed_version_id',
      PROJECT_CHANGED   => 'project_id'
  }

  attr_reader :event_type, :issue, :journal

  class << self
    def detect_change_event(event_type, issue, journal)
      DigestEvent.new(issue, journal, event_type) if case event_type
        when STATUS_CHANGED, PERCENT_CHANGED, ASSIGNEE_CHANGED, VERSION_CHANGED, PROJECT_CHANGED
          detect_journal_detail(journal, PROP_KEYS[event_type])
        when COMMENT_ADDED
          journal.notes.present?
        when ISSUE_CREATED
          false
        else
          raise DigestError.new "Unknown event type (#{event_type})"
      end
    end

    def detect_journal_detail(journal, prop_key)
      journal.details.detect do |d|
        d.property == 'attr' && d.prop_key == prop_key && d.old_value != d.value
      end
    end
  end

  def old_value
    journal_detail && journal_detail.old_value
  end

  def value
    journal_detail && journal_detail.value
  end

  private

  def initialize(event_type, issue, journal = nil)
    @event_type, @issue, @journal = event_type, issue, journal
  end

  def journal_detail
    @journal_detail ||= begin
      self.class.detect_journal_detail(journal, PROP_KEYS[event_type]) if journal
    end
  end
end
