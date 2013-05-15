class DigestRule < ActiveRecord::Base
  ALL = 'all'
  SELECTED = 'selected'
  NOT_SELECTED = 'not_selected'
  MEMBER = 'member'
  AUTHOR = 'author'
  PROJECT_SELECTOR_VALUES = [ALL, SELECTED, NOT_SELECTED, MEMBER, AUTHOR]

  DAILY = 'daily'
  WEEKLY = 'weekly'
  MONTHLY = 'monthly'
  RECURRENT_VALUES = [DAILY, WEEKLY, MONTHLY]

  belongs_to :user

  acts_as_list :scope => :user

  serialize :projects, Array
  serialize :events, Hash

  select2_ids :projects

  validates :project_selector, :inclusion => { :in => PROJECT_SELECTOR_VALUES }
  validates :recurrent, :inclusion => { :in => RECURRENT_VALUES }
end
