module RedmineDigest
  class Digest
    # batch size for fetching issues
    ISSUE_BATCH_SIZE = 300

    attr_reader :digest_rule, :time_to

    delegate :name, :user, :recurrent, :project_selector, :all_involved_only?,
             to: :digest_rule, allow_nil: true

    def initialize(digest_rule, time_to = nil, issue_limit = nil)
      @digest_rule  = digest_rule
      @time_to_base = time_to
      @issue_limit  = issue_limit
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

    def template_path(partial = 'digest')
      "digests/#{digest_rule.template}/#{partial}"
    end

    private

    def fetch_issues
      raise 'DigestRule#user must be filled' if user.nil?

      d_issues = []

      fetch_issue_ids.in_groups_of(ISSUE_BATCH_SIZE) do |issue_ids|
        get_issues_scope(issue_ids.compact).each do |issue|
          d_issue = get_digest_issue_with_events(issue)
          d_issues << d_issue if wants_created? ? d_issue.any_events? : d_issue.any_changes_events?
        end
      end

      d_issues
    end

    def get_digest_issue_with_events(issue)
      d_issue = DigestIssue.new(
        id:              issue.id,
        subject:         issue.subject,
        status_id:       issue.status_id,
        project_id:      issue.project_id,
        project_name:    issue.project.name,
        created_on:      issue.created_on,
        last_updated_on: issue.created_on,
        priority:        issue.priority
      )

      if include_issue_add_event?(issue)
        event = DigestEventFactory.new_event(
          DigestEvent::ISSUE_CREATED, issue.id, issue.created_on, issue.author)
        d_issue.events[DigestEvent::ISSUE_CREATED] << event
      end

      # read all journal updates, add indice and remove private_notes
      journals = issue.journals.sort_by(&:id)
      journals.each_with_index { |j, i| j.indice = i + 1 }

      journals.each do |journal|
        next unless include_issue_edit_event?(journal)

        events            = digest_rule.find_events_by_journal(journal)

        # get status_id from change history
        status_id_change  = events.detect { |e| e.event_type == DigestEvent::STATUS_CHANGED }
        d_issue.status_id = status_id_change.value if status_id_change

        next if journal.private_notes? &&
          !user.allowed_to?(:view_private_notes, issue.project)

        events.each do |event|
          d_issue.last_updated_on = journal.created_on
          d_issue.events[event.event_type] << event
        end
      end
      d_issue
    end

    def fetch_issue_ids
      all_issue_ids = get_changed_issue_ids
      all_issue_ids += get_created_issue_ids if wants_created?
      all_issue_ids.uniq!
      all_issue_ids = all_issue_ids.take(@issue_limit) if @issue_limit
      all_issue_ids
    end

    def include_issue_edit_event?(journal)
      return false unless in_time_frame?(journal.created_on)
      !(digest_rule.notify_only? && user_will_be_notified?(journal))
    end

    def user_will_be_notified?(journal)
      journal.notify? && notified_events?(journal) && user_in_recipients?(journal)
    end

    def user_in_recipients?(issue_or_journal)
      (issue_or_journal.watcher_recipients + issue_or_journal.recipients).include?(user.mail)
    end

    def notified_events?(journal)
      Setting.notified_events.include?('issue_updated') ||
        (Setting.notified_events.include?('issue_note_added') && journal.notes.present?) ||
        (Setting.notified_events.include?('issue_status_updated') && journal.new_status.present?) ||
        (Setting.notified_events.include?('issue_priority_updated') && journal.new_value_for('priority_id').present?)
    end

    def include_issue_add_event?(issue)
      return false unless in_time_frame?(issue.created_on)

      skip_digest = digest_rule.notify_only? &&
        Setting.notified_events.include?('issue_added') &&
        user_in_recipients?(issue)

      !skip_digest
    end

    def in_time_frame?(datetime)
      datetime >= time_from && datetime < time_to
    end

    def wants_created?
      digest_rule.event_type_enabled?(DigestEvent::ISSUE_CREATED)
    end

    def get_sorted_digest_issues
      result = ActiveSupport::OrderedHash.new
      IssueStatus.sorted.each do |status|
        result[status] = issues.
          find_all { |i| i.status_id.to_i == status.id }.
          sort { |a, b| b.sort_key <=> a.sort_key }
      end
      result
    end

    def get_time_to
      @time_to_base ||= Date.current.midnight
    end

    def get_changed_issue_ids
      get_journal_scope.
        where('journals.created_on >= ? and journals.created_on < ?', time_from, time_to).
        uniq.pluck(:journalized_id)
    end

    def get_created_issue_ids
      issues = Issue.where('issues.project_id in (?)', project_ids).
          where('issues.created_on >= ? and issues.created_on < ?', time_from, time_to)
      issues = issues.where('(issues.assigned_to_id = ? OR issues.author_id = ?)', user.id, user.id) if all_involved_only?
      issues.uniq.pluck(:id)
    end

    def get_issues_scope(issue_ids)
      Issue.joins(:project).includes(:author, :project, journals: [:user, :details]).
        where('issues.id in (?)', issue_ids).
        where(Issue.visible_condition(user))
    end

    def get_journal_scope
      if all_involved_only?
        get_journal_all_involved_scope
      else
        Journal.joins(:issue).where('issues.project_id in (?)', project_ids)
      end
    end

    def get_journal_all_involved_scope
      Journal.joins(:issue).
          joins("LEFT JOIN journal_details ON journals.id = journal_details.journal_id AND property = 'attr' AND prop_key = 'assigned_to_id'").
          joins("LEFT JOIN watchers ON watchers.watchable_type='Issue' AND watchers.watchable_id = issues.id").
          where('watchers.user_id = ? OR issues.author_id = ? OR issues.assigned_to_id = ? OR
                 journal_details.old_value = ? OR journal_details.value = ? OR journals.user_id = ?',
                 user.id, user.id, user.id, user.id, user.id, user.id)

    end

    def project_ids
      @project_ids ||= digest_rule.affected_project_ids
    end

    def use_user_time_zone(&block)
      Time.use_zone(user.time_zone, &block)
    end
  end
end
