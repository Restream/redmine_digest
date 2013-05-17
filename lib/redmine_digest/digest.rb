module RedmineDigest
  class Digest
    # batch size for fetching issues
    ISSUE_BATCH_SIZE = 300

    attr_reader :digest_rule, :date_to

    def initialize(digest_rule, date_to = Date.today)
      @digest_rule = digest_rule
      @date_to = date_to
    end

    def issues
      @issues ||= fetch_issues
    end

    def date_from
      @date_from ||= begin
        case digest_rule.recurrent
          when DigestRule::DAILY
            date_to - 1.day
          when DigestRule::WEEKLY
            date_to - 1.week
          when DigestRule::MONTHLY
            date_to - 1.month
          else
            raise DigestError.new "Unknown recurrent type (#{digest_rule.recurrent})"
        end
      end
    end

    private

    def fetch_issues
      d_issues = []

      get_issues_scope.find_each(:batch_size => ISSUE_BATCH_SIZE) do |issue|

        d_issue = DigestIssue.new(
            :id => issue.id,
            :subject => issue.subject,
            :status_id => issue.status_id
        )

        if issue.created_on >= date_from && issue.created_on < date_to
          d_issue.new? = true
          d_issue.events << DigestEvent.new(DigestEvent::ISSUE_CREATED, issue)
        end

        # read all journal updates, add indice and remove private_notes
        journals = issue.journals
        journals.sort_by(&:id).each_with_index { |j, i| j.indice = i + 1 }
        journals.reject!(&:private_notes?) unless digest_rule.user.allowed_to?(:view_private_notes, issue.project)

        journals.each do |journal|
          next if journal.created_on < date_from || journal.created_on >= date_to

          # get status_id from change history
          status_id_change = DigestEvent.detect_journal_detail(journal, 'status_id')
          d_issue.status_id = status_id_change.value if status_id_change

          next if journal.private_notes? &&
                  !digest_rule.user.allowed_to?(:view_private_notes, issue.project)

          digest_rule.event_ids.each do |event_type|
            event = DigestEvent.detect_change_event(event_type, issue, journal)
            d_issue.events << event if event
          end
        end
      end

      d_issues
    end

    def get_issues_scope
      Issue.includes(:project, :journals => [:user, :details]).
          where('journals.created_on >= ?', date_from).
          where('journals.created_on < ?', date_to).
          where(Issue.visible_condition(digest_rule.user))
    end
  end
end
