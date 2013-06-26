class DigestEvent
  STATUS_CHANGED    = :status_changed
  PERCENT_CHANGED   = :percent_changed
  ASSIGNEE_CHANGED  = :assignee_changed
  VERSION_CHANGED   = :version_changed
  PROJECT_CHANGED   = :project_changed
  COMMENT_ADDED     = :comment_added
  ISSUE_CREATED     = :issue_created

  TYPES = [STATUS_CHANGED, PERCENT_CHANGED, ASSIGNEE_CHANGED, VERSION_CHANGED,
           PROJECT_CHANGED, COMMENT_ADDED, ISSUE_CREATED]

  PROP_KEYS = {
      STATUS_CHANGED    => 'status_id',
      PERCENT_CHANGED   => 'done_ratio',
      ASSIGNEE_CHANGED  => 'assigned_to_id',
      VERSION_CHANGED   => 'fixed_version_id',
      PROJECT_CHANGED   => 'project_id'
  }

  # length of notes preview
  NOTES_LENGTH = 100

  include Redmine::I18n

  attr_reader :event_type, :issue_id, :created_on, :user, :journal

  class << self
    def detect_change_event(event_type, issue_id, created_on, user, journal)
      DigestEvent.new(event_type, issue_id, created_on, user, journal) if has_change(event_type, journal)
    end

    def detect_journal_detail(journal, prop_key)
      journal.details.detect do |d|
        d.property == 'attr' && d.prop_key == prop_key && d.old_value != d.value
      end
    end

    private

    def has_change(event_type, journal)
      case event_type.to_sym
        when STATUS_CHANGED, PERCENT_CHANGED, ASSIGNEE_CHANGED, VERSION_CHANGED, PROJECT_CHANGED
          true if detect_journal_detail(journal, PROP_KEYS[event_type])
        when COMMENT_ADDED
          journal.notes.present?
        when ISSUE_CREATED
          false
        else
          raise RedmineDigest::DigestError.new "Unknown event type (#{event_type})"
      end
    end
  end

  def old_value
    journal_detail && journal_detail.old_value
  end

  def value
    event_type == COMMENT_ADDED ? journal.notes : (journal_detail && journal_detail.value)
  end

  def formatted_old_value
    format_value(old_value)
  end

  def formatted_value
    format_value(value)
  end

  def event_summary
    user_stamp = "#{format_time(created_on)} #{user}"
    case event_type
      when STATUS_CHANGED, PERCENT_CHANGED, ASSIGNEE_CHANGED, VERSION_CHANGED, PROJECT_CHANGED
        "#{user_stamp}: #{formatted_old_value} -> #{formatted_value}"
      when COMMENT_ADDED
        "#{user_stamp}: #{value}"
      when ISSUE_CREATED
        user_stamp
      else
        raise RedmineDigest::DigestError.new "Unknown event type (#{event_type})"
    end
  end

  def indice
    journal ? journal.indice : 0
  end

  def initialize(event_type, issue_id, created_on, user, journal = nil)
    @event_type, @issue_id, @created_on, @user, @journal =
        event_type, issue_id, created_on, user, journal
  end

  private

  def format_value(val)
    return '-' if val.nil?
    case event_type
      when STATUS_CHANGED
        IssueStatus.find(val)
      when PERCENT_CHANGED
        "#{val}%"
      when ASSIGNEE_CHANGED
        User.find(val)
      when VERSION_CHANGED
        Version.find(val)
      when COMMENT_ADDED
        # TODO: may be first X characters?
        val.length > NOTES_LENGTH ?
            "\"#{val.gsub("\n",'')[0..NOTES_LENGTH]}...\"" : "\"#{val}\""
      when PROJECT_CHANGED
        Project.find(val)
      else
        val
    end
  rescue
    '<unknown>'
  end

  def journal_detail
    @journal_detail ||= begin
      self.class.detect_journal_detail(journal, PROP_KEYS[event_type]) if journal
    end
  end
end
