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
      DigestEvent.new(event_type, issue, journal) if case event_type
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
    journal_detail && format_value(journal_detail.old_value)
  end

  def value
    journal_detail && format_value(journal_detail.value)
  end

  def formatted_old_value
    format_value(old_value)
  end

  def formatted_value
    format_value(value)
  end

  def event_summary
    user_stamp = "#{I18n.l(created_on, :fromat => :short)} #{user}"
    case event_type
      when STATUS_CHANGED, PERCENT_CHANGED, ASSIGNEE_CHANGED, VERSION_CHANGED, PROJECT_CHANGED
        [user_stamp, formatted_value].join(': ')
      when COMMENT_ADDED
        # TODO: may be first X characters?
        [user_stamp, journal.notes].join(': ')
      when ISSUE_CREATED
        user_stamp
      else
        raise DigestError.new "Unknown event type (#{event_type})"
    end
  end

  def indice
    journal ? journal.indice : 0
  end

  def created_on
    journal ? journal.created_on : issue.created_on
  end

  def user
    journal ? journal.user : issue.author
  end

  private

  def format_value(val)
    return 'NULL' if val.nil?
    case event_type
      when STATUS_CHANGED
        IssueStatus.find(val)
      when ASSIGNEE_CHANGED
        User.find(val)
      when VERSION_CHANGED
        Version.find(val)
      when PROJECT_CHANGED
        Project.find(val)
      else
        val
    end
  rescue
    'Unknown'
  end

  def initialize(event_type, issue, journal = nil)
    @event_type, @issue, @journal = event_type, issue, journal
  end

  def journal_detail
    @journal_detail ||= begin
      self.class.detect_journal_detail(journal, PROP_KEYS[event_type]) if journal
    end
  end
end
