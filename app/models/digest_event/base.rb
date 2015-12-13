class DigestEvent::Base

  # length of notes preview
  NOTES_LENGTH = 300

  include Redmine::I18n
  include Comparable

  attr_reader :event_type, :issue_id, :created_on, :user, :journal, :journal_detail

  def initialize(event_type, issue_id, created_on, user, journal = nil, journal_detail = nil)
    @event_type, @issue_id, @created_on, @user, @journal, @journal_detail =
        event_type, issue_id, created_on, user, journal, journal_detail
  end

  def old_value
    journal_detail && journal_detail.old_value
  end

  def value
    journal_detail && journal_detail.value
  end

  def formatted_old_value
    format_value(old_value)
  end

  def formatted_value
    format_value(value)
  end

  def event_summary
    "#{user_stamp}: #{formatted_old_value} -> #{formatted_value}"
  end

  def user_stamp
    "#{format_time(created_on)} #{user}"
  end

  def indice
    journal ? journal.indice : 0
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
    if event_type == other.event_type
      created_on <=> other.created_on
    else
      DigestEvent::TYPES.index(event_type) <=> DigestEvent::TYPES.index(other.event_type)
    end
  end

  private

  def format_value(val)
    val.nil? ? '-' : format_other_attr(val)
  rescue
    '<unknown>'
  end

  def format_other_attr(val)
    case journal_detail.property
      when 'attr'
        field = journal_detail.prop_key.to_s.gsub(/_id$/, '')
        case journal_detail.prop_key

          when 'due_date', 'start_date'
            format_date(val.to_date) if val

          when 'project_id', 'status_id', 'tracker_id', 'assigned_to_id', 'assigned_to',
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
  end

  def cutted_text(text)
    return '""' if text.blank?
    text.length > NOTES_LENGTH ?
        "\"#{text.gsub("\n", '')[0..NOTES_LENGTH]}...\"" :
        "\"#{text}\""
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
