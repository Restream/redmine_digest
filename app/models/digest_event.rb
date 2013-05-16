class DigestEvent
  STATUS_CHANGED = 'status_changed'
  PERCENT_CHANGED = 'percent_changed'
  ASSIGNEE_CHANGED = 'assignee_changed'
  VERSION_CHANGED = 'version_changed'
  PROJECT_CHANGED = 'project_changed'
  COMMENT_ADDED = 'comment_added'
  ISSUE_CREATED = 'issue_created'

  TYPES = [STATUS_CHANGED, PERCENT_CHANGED, ASSIGNEE_CHANGED, VERSION_CHANGED,
           PROJECT_CHANGED, COMMENT_ADDED, ISSUE_CREATED]
end
