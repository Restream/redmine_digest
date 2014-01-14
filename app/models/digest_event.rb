module DigestEvent
  ISSUE_CREATED       = :issue_created
  COMMENT_ADDED       = :comment_added
  ATTACHMENT_ADDED    = :attachment_added
  STATUS_CHANGED      = :status_changed
  PERCENT_CHANGED     = :percent_changed
  ASSIGNEE_CHANGED    = :assignee_changed
  VERSION_CHANGED     = :version_changed
  PROJECT_CHANGED     = :project_changed
  SUBJECT_CHANGED     = :subject_changed
  DESCRIPTION_CHANGED = :description_changed
  OTHER_ATTR_CHANGED  = :other_attr_changed

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
           DESCRIPTION_CHANGED,
           COMMENT_ADDED]

  PROP_KEYS = {
      'status_id'        => DigestEvent::STATUS_CHANGED,
      'done_ratio'       => DigestEvent::PERCENT_CHANGED,
      'assigned_to_id'   => DigestEvent::ASSIGNEE_CHANGED,
      'fixed_version_id' => DigestEvent::VERSION_CHANGED,
      'project_id'       => DigestEvent::PROJECT_CHANGED,
      'subject'          => DigestEvent::SUBJECT_CHANGED,
      'description'      => DigestEvent::DESCRIPTION_CHANGED
  }
end
