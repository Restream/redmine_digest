module DigestRulesHelper
  def project_selector_options
    DigestRule::PROJECT_SELECTOR_VALUES.map do |v|
      [ l(v, :scope => 'project_selector'), v ]
    end
  end

  def projects_options
    root_projects = Project.visible.roots.order(:name)
    projects_tree(root_projects).map do |project|
      prefix = ' << ' * project.ancestors.count
      [prefix + project.name, project.id]
    end
  end

  def projects_tree(projects)
    result = []
    projects.each do |project|
      result << project
      result += projects_tree(project.children) if project.children.any?
    end
    result
  end

  def find_select2_js_locale(lang)
    url = "select2/select2_locale_#{lang}"
    file_path = File.join(Rails.root, "/plugin_assets/redmine_digest/#{url}")
    url if File.exists?(file_path)
  end
end
