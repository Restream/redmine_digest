class DigestEvent::VersionChanged < DigestEvent::Base
  private

  def format_value(val)
    val.blank? ? '-' : Version.find(val)
  rescue ActiveRecord::RecordNotFound
    '<not found>'
  end
end
