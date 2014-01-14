class DigestEvent::StatusChanged < DigestEvent::Base
  private

  def format_value(val)
    val.blank? ? '-' : IssueStatus.find(val)
  rescue ActiveRecord::RecordNotFound
    '<not found>'
  end
end
