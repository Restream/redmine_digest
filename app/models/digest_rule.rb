class DigestRule < ActiveRecord::Base
  ALL = 'all'
  SELECTED = 'selected'
  NOT_SELECTED = 'not_selected'
  MEMBER = 'member'
  MEMBER_NOT_SELECTED = 'member_not_selected'
  PROJECT_SELECTOR_VALUES = [ALL, SELECTED, NOT_SELECTED, MEMBER, MEMBER_NOT_SELECTED]

  DAILY = 'daily'
  WEEKLY = 'weekly'
  MONTHLY = 'monthly'
  RECURRENT_TYPES = [DAILY, WEEKLY, MONTHLY]

  belongs_to :user

  serialize :project_ids, Array
  serialize :event_ids

  attr_accessible :active, :name, :raw_project_ids, :project_selector,
                  :recurrent, :event_ids, :move_to

  validates :name, :presence => true
  validates :project_selector, :inclusion => { :in => PROJECT_SELECTOR_VALUES }
  validates :recurrent, :inclusion => { :in => RECURRENT_TYPES }

  scope :active, -> { where('active = ?', true) }

  scope :daily,   -> { where(:recurrent => DAILY) }
  scope :weekly,  -> { where(:recurrent => WEEKLY) }
  scope :monthly, -> { where(:recurrent => MONTHLY) }

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

  def include_issue_on_create?(issue)
    event_type_enabled?(DigestEvent::ISSUE_CREATED) &&
        affected_project_ids.include?(issue.project_id)
  end

  def include_journal_on_update?(journal)
    has_updates = event_types.inject(false) do |res, event_type|
      res || DigestEvent.has_change?(event_type, journal)
    end
    has_updates && affected_project_ids.include?(journal.issue.project_id)
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

  private

  def get_projects_scope
    case project_selector
      when ALL
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
    self.active = true if active.nil?
    self.project_selector ||= MEMBER
    self.recurrent ||= WEEKLY
    self.event_ids ||= DigestEvent::TYPES.dup
  end
end
