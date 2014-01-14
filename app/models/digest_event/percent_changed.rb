class DigestEvent::PercentChanged < DigestEvent::Base
  private

  def format_value(val)
    val.blank? ? '-' : "#{val}%"
  end
end
