class DigestEvent::AssigneeChanged < DigestEvent::Base
  private

  def format_value(val)
    val.blank? ? '-' : Principal.find(val)
  rescue ActiveRecord::RecordNotFound
    '<not found>'
  end
end
