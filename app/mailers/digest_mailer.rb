class DigestMailer < ActionMailer::Base

  # Overview
  # Changed issues
  #   New Status (group issues by status)
  #     Issue (Issues sorted by last change time)
  #       #000 subject -> (% done, assignee, comments)
  #
  def digest_email(digest)
    @digest = digest
  end

end
