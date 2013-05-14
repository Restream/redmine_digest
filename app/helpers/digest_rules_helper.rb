module DigestRulesHelper
  def project_selector_options
    DigestRule::PROJECT_SELECTOR_VALUES.map do |v|
      [ l(v, :scope => 'project_selector'), v ]
    end
  end
end
