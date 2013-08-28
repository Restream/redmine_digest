module RedmineDigest
  class Digest
    # batch size for fetching issues
    ISSUE_BATCH_SIZE = 300

    attr_reader :digest_rule, :time_to

    delegate :name, :user, :recurrent, :project_selector,
             :to => :digest_rule, :allow_nil => true

    def initialize(digest_rule, time_to = nil, issue_limit = nil)
      @digest_rule = digest_rule
      @time_to_base = time_to
      @issue_limit = issue_limit
    end

    def issues
      @issues ||= use_user_time_zone do
        fetch_issues
      end
    end

    def time_to
      @time_to ||= use_user_time_zone do
        get_time_to
      end
    end

    def time_from
      @time_from ||= use_user_time_zone do
        digest_rule.calculate_time_from(time_to)
      end
    end

    def sorted_digest_issues
      @sorted_digest_issues ||= get_sorted_digest_issues
    end

    def projects_count
      @projects_count ||= issues.map(&:project_id).uniq.count
    end

    def many_projects?
      projects_count > 1
    end

    def project_names
      @projects_names ||= issues.map(&:project_name).uniq
    end

    private

    def fetch_issues
      raise 'DigestRule#user must be filled' if user.nil?

      all_issue_ids = get_changed_issue_ids
      all_issue_ids += get_created_issue_ids if wants_created?
      all_issue_ids.uniq!
      all_issue_ids = all_issue_ids.take(@issue_limit) if @issue_limit

      d_issues = []

      all_issue_ids.in_groups_of(ISSUE_BATCH_SIZE) do |issue_ids|

        get_issues_scope(issue_ids.compact).each do |issue|

          d_issue = DigestIssue.new(
              :id => issue.id,
              :subject => issue.subject,
              :status_id => issue.status_id,
              :project_id => issue.project_id,
              :project_name => issue.project.name,
              :created_on => issue.created_on,
              :last_updated_on => issue.created_on,
              :priority => issue.priority
          )

          if include_issue_add_event?(issue)
            event = DigestEvent.new(DigestEvent::ISSUE_CREATED,
                                    issue.id,
                                    issue.created_on,
                                    issue.author)
            d_issue.events[DigestEvent::ISSUE_CREATED] << event
          end

          # read all journal updates, add indice and remove private_notes
          journals = issue.journals
          journals.sort_by(&:id).each_with_index { |j, i| j.indice = i + 1 }

          journals.each do |journal|
            next unless include_issue_edit_event?(journal)

            events = digest_rule.find_events_by_journal(journal)

            # get status_id from change history
            status_id_change = events.detect{ |e| e.event_type == DigestEvent::STATUS_CHANGED }
            d_issue.status_id = status_id_change.value if status_id_change

            next if journal.private_notes? &&
                    !user.allowed_to?(:view_private_notes, issue.project)

            events.each do |event|
              d_issue.last_updated_on = journal.created_on
              d_issue.events[event.event_type] << event
            end
          end

          if wants_created?
            d_issues << d_issue if d_issue.any_events?
          else
            d_issues << d_issue if d_issue.any_changes_events?
          end

        end

      end

      d_issues
    end

    def include_issue_edit_event?(journal)
      return false if journal.created_on < time_from ||
                      journal.created_on >= time_to

      skip_digest = digest_rule.notify_only? &&
          (journal.notify? &&
              (Setting.notified_events.include?('issue_updated') ||
                  (Setting.notified_events.include?('issue_note_added') && journal.notes.present?) ||
                  (Setting.notified_events.include?('issue_status_updated') && journal.new_status.present?) ||
                  (Setting.notified_events.include?('issue_priority_updated') && journal.new_value_for('priority_id').present?)
              )) &&
          (journal.watcher_recipients + journal.recipients).include?(user.mail)

      !skip_digest
    end

    def include_issue_add_event?(issue)
      return false if issue.created_on < time_from ||
                      issue.created_on >= time_to

      skip_digest = digest_rule.notify_only? &&
          Setting.notified_events.include?('issue_added') &&
          (issue.watcher_recipients + issue.recipients).include?(user.mail)

      !skip_digest
    end

    def wants_created?
      digest_rule.event_type_enabled?(DigestEvent::ISSUE_CREATED)
    end

    def get_sorted_digest_issues
      result = ActiveSupport::OrderedHash.new
      IssueStatus.sorted.each do |status|
        result[status] = issues.
            find_all { |i| i.status_id.to_i == status.id }.
            sort{ |a, b| b.sort_key <=> a.sort_key }
      end
      result
    end

    def get_time_to
      @time_to_base ||= Date.current.midnight
    end

    def get_changed_issue_ids
      Journal.joins(:issue).where('issues.project_id in (?)', project_ids).
          where('journals.created_on >= ? and journals.created_on < ?', time_from, time_to).
          uniq.pluck(:journalized_id)
    end

    def get_created_issue_ids
      Issue.where('issues.project_id in (?)', project_ids).
          where('issues.created_on >= ? and issues.created_on < ?', time_from, time_to).
          uniq.pluck(:id)
    end

    def get_issues_scope(issue_ids)
      Issue.includes(:author, :project, :journals => [:user, :details]).
          where('issues.id in (?)', issue_ids).
          where(Issue.visible_condition(user))
    end

    def project_ids
      @project_ids ||= digest_rule.affected_project_ids
    end

    def use_user_time_zone(&block)
      Time.use_zone(user.time_zone, &block)
    end
  end
end
