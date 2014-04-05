module DigestRulesHelper
  def project_selector_options_for_select
    DigestRule::PROJECT_SELECTOR_VALUES.map do |v|
      [ l(v, :scope => 'project_selector'), v ]
    end
  end

  def project_ids_options_for_select
    user_projects = User.current.memberships.collect(&:project).compact.select(&:active?).uniq
    visible_projects = Project.active.visible
    active_projects = Project.active
    root_projects = Project.cache_children(active_projects).sort
    result = []
    result << {
        :text => l(:label_my_projects),
        :children => projects_tree_for_selector(root_projects,
                                                :only => user_projects,
                                                :allowed => visible_projects)
    }
    result << {
        :text => l(:description_choose_project),
        :children => projects_tree_for_selector(root_projects,
                                                :only => visible_projects,
                                                :allowed => visible_projects)
    }
    result
  end

  # expected option keys are:
  #  :only => []    - array of projects that will be included in tree
  #  :except => []  - array of projects that will be excluded from tree
  def projects_tree_for_selector(projects, options = {})
    result = []
    projects.each do |project|

      children = project.cached_children.sort
      children_tree = projects_tree_for_selector(children, options)

      node = {}

      node.merge!(
          :text => project.name
      ) if show_project_as_leaf?(project, options)

      node.merge!(
          :text => project.name,
          :children => children_tree
      ) if children_tree.any?

      node.merge!(
          :id => project.id
      ) if !node.empty? && allowed_to_select?(project, options)

      result << node unless node.empty?
    end
    result
  end

  def notify_options_for_select
    DigestRule::NOTIFY_OPTIONS.map do |v|
      [ l(v, :scope => 'notify_options'), v ]
    end
  end

  def recurrent_options_for_select
    DigestRule::RECURRENT_TYPES.map do |v|
      [ l(v, :scope => 'recurrent_types'), v ]
    end
  end

  def templates_for_select
    DigestRule::TEMPLATES.map do |v|
      [ l(v, :scope => 'digest_template'), v ]
    end
  end

  def event_type_id(event_type)
    "digest_rule_event_type_#{event_type}"
  end

  def digest_issue_url(di)
    {
        :host => Setting.host_name,
        :protocol => Setting.protocol,
        :controller => 'issues',
        :action => 'show',
        :id => di.id
    }
  end

  def digest_issue_text(di, show_project_name = true)
    if show_project_name
      "##{di.id} [#{di.project_name}] #{di.subject}"
    else
      "##{di.id} #{di.subject}"
    end
  end

  def digest_issue_title(di)
    [
        di.new_issue? ?
            "#{l(:label_issue_added)} #{format_time(di.created_on)}" : nil,
        di.changes_event_types.any? ?
            "#{l(:label_issue_updated)} #{format_time(di.last_updated_on)}" : nil
    ].compact.join(', ')
  end

  def event_type_color(event_type)
    case event_type
      when DigestEvent::STATUS_CHANGED then '#defff1'
      when DigestEvent::PERCENT_CHANGED then '#d8d8ff'
      when DigestEvent::ASSIGNEE_CHANGED then '#fbe3ff'
      when DigestEvent::VERSION_CHANGED then '#ffe1e3'
      when DigestEvent::PROJECT_CHANGED then '#fffcde'
      when DigestEvent::SUBJECT_CHANGED then '#FF8E8E'
      when DigestEvent::OTHER_ATTR_CHANGED then '#E7E9E6'
      when DigestEvent::COMMENT_ADDED then '#e0ffe1'
      when DigestEvent::ATTACHMENT_ADDED then '#DFF3FF'
      when DigestEvent::ISSUE_CREATED then '#e1ffe3'
      else 'gray'
    end
  end

  def digest_issue_changes_timeline(digest_issue)
    all_changes = digest_issue.changes.sort { |a, b| a.created_on <=> b.created_on }
    all_changes.group_by(&:created_on)
  end

  def digest_event_diff(event)
    diff_with_classes = Redmine::Helpers::Diff.new(event.value, event.old_value).to_html
    diff_with_classes.
        gsub(/class="diff_in"/, 'style="background: #afa;"').
        gsub(/class="diff_out"/, 'style="background: #faa;"').html_safe
  end

  def format_event_text(event)
    case event.event_type
      when DigestEvent::DESCRIPTION_CHANGED
        simple_format_without_paragraph digest_event_diff(event)
      when DigestEvent::COMMENT_ADDED
        simple_format_without_paragraph event.formatted_value
      else
        event.formatted_value
    end
  end

  private

  def show_project_as_leaf?(project, options = {})
    return false if options[:except] && options[:except].include?(project)
    return options[:only].include?(project) if options[:only]
    true
  end

  def allowed_to_select?(project, options = {})
    options[:allowed] ? options[:allowed].include?(project) : false
  end
end
