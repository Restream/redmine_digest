module RedmineDigest
  class Digest
    # batch size for fetching issues
    ISSUE_BATCH_SIZE = 300

    attr_reader :digest_rule, :date_to

    delegate :name, :recurrent, :to => :digest_rule, :allow_nil => true

    def initialize(digest_rule, date_to = nil)
      @digest_rule = digest_rule
      @date_to = date_to || Date.today.to_time
    end

    def issues
      @issues ||= fetch_issues
    end

    def date_from
      @date_from ||= get_date_from
    end

    def sorted_digest_issues
      @sorted_digest_issues ||= get_sorted_digest_issues
    end

    private

    def fetch_issues
      all_issue_ids = get_changed_issue_ids

      d_issues = []

      all_issue_ids.in_groups_of(ISSUE_BATCH_SIZE) do |issue_ids|

        get_issues_scope(issue_ids).each do |issue|

          d_issue = DigestIssue.new(
              :id => issue.id,
              :subject => issue.subject,
              :status_id => issue.status_id,
              :project_name => issue.project.name,
              :created_on => issue.created_on,
              :last_updated_on => issue.created_on
          )

          if issue.created_on >= date_from && issue.created_on < date_to
            event = DigestEvent.new(DigestEvent::ISSUE_CREATED,
                                    issue.id,
                                    issue.created_on,
                                    issue.author.to_s)
            d_issue.events[DigestEvent::ISSUE_CREATED] << event
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

            digest_rule.event_types.each do |event_type|
              event = DigestEvent.detect_change_event(event_type,
                                                      issue.id,
                                                      journal.created_on,
                                                      journal.user.to_s,
                                                      journal)
              if event
                d_issue.last_updated_on = journal.created_on
                d_issue.events[event_type] << event
              end
            end
          end

          d_issues << d_issue if d_issue.any_events?
        end

      end

      d_issues
    end

    def get_sorted_digest_issues
      result = ActiveSupport::OrderedHash.new
      IssueStatus.sorted.each do |status|
        iss = issues.find_all { |i| i.status_id == status.id }.sort_by(&:last_updated_on)
        result[status] = iss
      end
      result
    end

    def get_date_from
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

    def get_changed_issue_ids
      ids = Journal.where(
          'journals.created_on >= ? and journals.created_on < ?',
          date_from,
          date_to
      ).uniq.pluck(:journalized_id)
      ids += Issue.where(
          'issues.created_on >= ? and issues.created_on < ?',
          date_from,
          date_to
      ).uniq.pluck(:id)
      ids.uniq
    end

    def get_issues_scope(issue_ids)
      Issue.includes(:project, :journals => [:user, :details]).
          where('issues.id in (?)', issue_ids).
          where(Issue.visible_condition(digest_rule.user))
    end
  end
end
