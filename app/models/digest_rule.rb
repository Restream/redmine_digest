class DigestRule < ActiveRecord::Base
  ALL = 'all'
  SELECTED = 'selected'
  NOT_SELECTED = 'not_selected'
  MEMBER = 'member'
  PROJECT_SELECTOR_VALUES = [ALL, SELECTED, NOT_SELECTED, MEMBER]

  DAILY = 'daily'
  WEEKLY = 'weekly'
  MONTHLY = 'monthly'
  RECURRENT_TYPES = [DAILY, WEEKLY, MONTHLY]

  belongs_to :user

  serialize :project_ids, Array
  serialize :event_ids, Array

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
    event_ids.map(&:to_sym)
  end

  private

  def set_default_values
    self.active = true if active.nil?
    self.project_selector ||= MEMBER
    self.recurrent ||= WEEKLY
    self.event_ids += DigestEvent::TYPES if event_ids.nil? || event_ids.empty?
  end
end
