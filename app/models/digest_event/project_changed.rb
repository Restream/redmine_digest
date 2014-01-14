class DigestEvent::ProjectChanged < DigestEvent::Base
  private

  def format_value(val)
    val.blank? ? '-' : Project.find(val)
  rescue ActiveRecord::RecordNotFound
    '<not found>'
  end
end
