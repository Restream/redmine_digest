class DigestRule < ActiveRecord::Base
  ALL                     = 'all'
  SELECTED                = 'selected'
  NOT_SELECTED            = 'not_selected'
  MEMBER                  = 'member'
  MEMBER_NOT_SELECTED     = 'member_not_selected'
  ALL_INVOLVED            = 'all_involved'
  PROJECT_SELECTOR_VALUES = [ALL, SELECTED, NOT_SELECTED, MEMBER, MEMBER_NOT_SELECTED, ALL_INVOLVED]

  NOTIFY_AND_DIGEST = 'all'
  NOTIFY_ONLY       = 'notify'
  DIGEST_ONLY       = 'digest'
  NOTIFY_OPTIONS    = [NOTIFY_AND_DIGEST, NOTIFY_ONLY, DIGEST_ONLY]

  DAILY           = 'daily'
  WEEKLY          = 'weekly'
  MONTHLY         = 'monthly'
  RECURRENT_TYPES = [DAILY, WEEKLY, MONTHLY]

  TEMPLATE_SHORT    = 'short'
  TEMPLATE_DETAIL   = 'detail'
  TEMPLATE_TIMELINE = 'timeline'
  TEMPLATES         = [TEMPLATE_SHORT, TEMPLATE_DETAIL, TEMPLATE_TIMELINE]

  belongs_to :user

  serialize :project_ids, Array
  serialize :event_ids

  attr_accessible :active, :name, :raw_project_ids, :project_selector,
                  :notify, :recurrent, :event_ids, :move_to, :template

  validates :name, presence: true
  validates :project_selector, inclusion: { in: PROJECT_SELECTOR_VALUES }
  validates :notify, inclusion: { in: NOTIFY_OPTIONS }
  validates :recurrent, inclusion: { in: RECURRENT_TYPES }
  validates :template, inclusion: { in: TEMPLATES }

  scope :active, -> { joins(:user).where("active = ? AND #{ User.table_name }.status = ?", true, User::STATUS_ACTIVE) }

  scope :digest_only, -> { where('notify = ?', DIGEST_ONLY) }

  scope :daily, -> { where(recurrent: DAILY) }
  scope :weekly, -> { where(recurrent: WEEKLY) }
  scope :monthly, -> { where(recurrent: MONTHLY) }

  after_initialize :set_default_values

  def raw_project_ids=(comma_seperated_ids)
    self.project_ids = comma_seperated_ids.to_s.split ','
  end

  def raw_project_ids
    project_ids.join ','
  end

  def event_type_enabled?(event_type)
    event_types.include? event_type.to_sym
  end

  def event_types
    event_ids ? event_ids.map(&:to_sym) : []
  end

  def add_event_type(event_type)
    event_ids << event_type.to_s
  end

  def affected_project_ids
    Project.
      joins(:memberships).
      where(get_projects_scope).
      uniq.pluck('projects.id')
  end

  def calculate_time_from(time_to)
    case recurrent
      when DAILY
        time_to - 1.day
      when WEEKLY
        time_to - 1.week
      when MONTHLY
        time_to - 1.month
      else
        raise DigestError.new "Unknown recurrent type (#{recurrent})"
    end
  end

  def find_events_by_journal(journal)
    return [] unless affected_project_ids.include?(journal.issue.project_id)

    events = []

    issue_id   = journal.issue.id
    created_on = journal.created_on
    user       = journal.user

    if journal.notes.present? && event_type_enabled?(DigestEvent::COMMENT_ADDED)
      events << DigestEventFactory.new_event(
        DigestEvent::COMMENT_ADDED, issue_id, created_on, user, journal)
    end

    journal.details.each do |jdetail|
      event = event_for_journal_detail(journal, jdetail)
      events << event if event && event_type_enabled?(event.event_type)
    end

    events
  end

  def apply_for_created_issue?(issue)
    event_type_enabled?(DigestEvent::ISSUE_CREATED) &&
      affected_project_ids.include?(issue.project_id)
  end

  def apply_for_updated_issue?(journal)
    find_events_by_journal(journal).any?
  end

  def notify_and_digest?
    notify == NOTIFY_AND_DIGEST
  end

  def notify_only?
    notify == NOTIFY_ONLY
  end

  def digest_only?
    notify == DIGEST_ONLY
  end

  private

  def event_for_journal_detail(journal, jdetail)
    issue_id   = journal.journalized_id
    created_on = journal.created_on
    user       = journal.user

    if jdetail.property == 'attr' && DigestEvent::PROP_KEYS.has_key?(jdetail.prop_key)
      event_type = DigestEvent::PROP_KEYS[jdetail.prop_key]
      return DigestEventFactory.new_event(event_type, issue_id, created_on, user, journal, jdetail)
    end

    if jdetail.property == 'attachment'
      return DigestEventFactory.new_event(
        DigestEvent::ATTACHMENT_ADDED, issue_id, created_on, user, journal, jdetail)
    end

    DigestEventFactory.new_event(
      DigestEvent::OTHER_ATTR_CHANGED, issue_id, created_on, user, journal, jdetail)
  end

  def get_projects_scope
    case project_selector
      when ALL, ALL_INVOLVED
        nil
      when SELECTED
        ['projects.id in (?)', project_ids]
      when NOT_SELECTED
        ['projects.id not in (?)', project_ids]
      when MEMBER
        ['members.user_id = ?', user.id]
      when MEMBER_NOT_SELECTED
        ['members.user_id = ? and projects.id not in (?)', user.id, project_ids]
      else
        raise RedmineDigest::Error.new "Unknown project selector (#{project_selector})"
    end
  end

  def set_default_values
    self.active           = true if active.nil?
    self.project_selector ||= MEMBER
    self.notify           ||= NOTIFY_AND_DIGEST
    self.recurrent        ||= WEEKLY
    self.event_ids        ||= DigestEvent::TYPES.dup
    self.template         ||= TEMPLATE_SHORT
  end
end
