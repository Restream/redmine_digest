RedmineApp::Application.routes.draw do
  resources :digest_rules, :only => [:new, :create, :edit, :update, :destroy]
end
