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

  # order is matter. it is used in sorting
  TYPES = [ISSUE_CREATED,
           PROJECT_CHANGED,
           SUBJECT_CHANGED,
           ASSIGNEE_CHANGED,
           STATUS_CHANGED,
           PERCENT_CHANGED,
           VERSION_CHANGED,
           OTHER_ATTR_CHANGED,
           ATTACHMENT_ADDED,
           COMMENT_ADDED]

  PROP_KEYS = {
      'status_id'        => STATUS_CHANGED,
      'done_ratio'       => PERCENT_CHANGED,
      'assigned_to_id'   => ASSIGNEE_CHANGED,
      'fixed_version_id' => VERSION_CHANGED,
      'project_id'       => PROJECT_CHANGED,
      'subject'          => SUBJECT_CHANGED
  }

  # length of notes preview
  NOTES_LENGTH = 300

  include Redmine::I18n
  include Comparable

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

  def field_label
    return nil unless journal_detail
    case journal_detail.property
      when 'attr'
        field = journal_detail.prop_key.to_s.gsub(/_id$/, '')
        journal_detail.prop_key == 'parent_id' ?
            l(:field_parent_issue) :
            l(('field_' + field).to_sym)
      when 'cf'
        custom_field = CustomField.find_by_id(journal_detail.prop_key)
        custom_field.try :name
      else
        nil
    end
  end

  def <=>(other)
    TYPES.index(event_type) <=> TYPES.index(other.event_type)
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
      when OTHER_ATTR_CHANGED
        case journal_detail.property
          when 'attr'
            field = journal_detail.prop_key.to_s.gsub(/_id$/, '')
            case journal_detail.prop_key

              when 'due_date', 'start_date'
                format_date(val.to_date) if val

              when 'project_id', 'status_id', 'tracker_id', 'assigned_to_id',
                  'priority_id', 'category_id', 'fixed_version_id'
                find_name_by_reflection(field, val)

              when 'estimated_hours'
                "%0.02f" % val.to_f unless val.blank?

              when 'parent_id'
                "##{val}" unless val.blank?

              when 'is_private'
                l(val == '0' ? :general_text_No : :general_text_Yes) unless val.blank?

              else
                val
            end
          when 'cf'
            custom_field = CustomField.find_by_id(journal_detail.prop_key)
            if val && custom_field
              format_custom_field_value(val, custom_field.field_format)
            end
          else
            val
        end
      else
        val
    end
  rescue
    '<unknown>'
  end

  # Find the name of an associated record stored in the field attribute
  def find_name_by_reflection(field, id)
    association = Issue.reflect_on_association(field.to_sym)
    if association
      record = association.class_name.constantize.find_by_id(id)
      return record.name if record
    end
  end

  def format_custom_field_value(val, field_format)
    if val.is_a?(Array)
      val.collect {|v| format_custom_field_value(v, field_format)}.compact.sort.join(', ')
    else
      Redmine::CustomFieldFormat.format_value(val, field_format)
    end
  end

end
