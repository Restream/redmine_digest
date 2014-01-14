class DigestEvent::SubjectChanged < DigestEvent::Base
  private

  def format_value(val)
    val.nil? ? '-' : val
  end
end
