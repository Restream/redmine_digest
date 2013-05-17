class DigestMailer < ActionMailer::Base

  helper :digest_mailer

  # Overview
  # Changed issues
  #   New Status (group issues by status)
  #     Issue (Issues sorted by last change time)
  #       #000 subject -> (% done, assignee, comments)
  #
  def digest_email(digest)
    @digest = digest
    @sorted_digest_issues = ActiveSupport::OrderedHash.new
    IssueStatus.sorted.each do |status|
      iss = digest_issues.find_all { |i| i.status_id == status.id }.sort_by(&:last_updated_on)
      @sorted_digest_issues[status] = iss
    end
  end

end
