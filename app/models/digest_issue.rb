class DigestIssue < Dash
  property :id, :required => true
  property :subject, :required => true

  property :last_updated_on
  property :status_id

  property :new?, :default => false
  property :events, :default => []
end
