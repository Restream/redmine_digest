class DigestEvent
  ISSUE_CREATED      = :issue_created
  COMMENT_ADDED      = :comment_added
  ATTACHMENT_ADDED   = :attachment_added
  STATUS_CHANGED     = :status_changed
  PERCENT_CHANGED    = :percent_changed
  ASSIGNEE_CHANGED   = :assignee_changed
  VERSION_CHANGED    = :version_changed
  PROJECT_CHANGED    = :project_changed
  SUBJECT_CHANGED    = :subject_changed
  OTHER_ATTR_CHANGED = :other_attr_changed

  TYPES = [ISSUE_CREATED, COMMENT_ADDED, ATTACHMENT_ADDED,
           STATUS_CHANGED, PERCENT_CHANGED, ASSIGNEE_CHANGED, VERSION_CHANGED,
           PROJECT_CHANGED, SUBJECT_CHANGED, OTHER_ATTR_CHANGED]

  PROP_KEYS = {
      'status_id'        => STATUS_CHANGED,
      'done_ratio'       => PERCENT_CHANGED,
      'assigned_to_id'   => ASSIGNEE_CHANGED,
      'fixed_version_id' => VERSION_CHANGED,
      'project_id'       => PROJECT_CHANGED,
      'subject'          => SUBJECT_CHANGED
  }

  # length of notes preview
  NOTES_LENGTH = 100

  include Redmine::I18n

  attr_reader :event_type, :issue_id, :created_on, :user, :journal, :journal_detail

  def old_value
    journal_detail && journal_detail.old_value
  end

  def value
    event_type == COMMENT_ADDED ?
        journal.notes :
        (journal_detail && journal_detail.value)
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
      when ISSUE_CREATED
        user_stamp
      when COMMENT_ADDED
        "#{user_stamp}: #{value}"
      when ATTACHMENT_ADDED
        "#{user_stamp}: #{value}"
      when STATUS_CHANGED, PERCENT_CHANGED, ASSIGNEE_CHANGED,
          VERSION_CHANGED, PROJECT_CHANGED, SUBJECT_CHANGED, OTHER_ATTR_CHANGED
        "#{user_stamp}: #{formatted_old_value} -> #{formatted_value}"
      else
        raise RedmineDigest::DigestError.new "Unknown event type (#{event_type})"
    end
  end

  def indice
    journal ? journal.indice : 0
  end

  def initialize(event_type, issue_id, created_on, user, journal = nil, journal_detail = nil)
    @event_type, @issue_id, @created_on, @user, @journal, @journal_detail =
        event_type, issue_id, created_on, user, journal, journal_detail
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
end
