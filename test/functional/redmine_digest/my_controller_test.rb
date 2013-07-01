require File.expand_path('../../../test_helper', __FILE__)

class RedmineDigest::MyControllerTest < ActionController::TestCase
  fixtures :users, :user_preferences, :roles, :projects, :members, :member_roles,
           :issues, :issue_statuses, :trackers, :journals, :journal_details

  def setup
    @controller = MyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = User.find(1) # admin
    User.current = @user
    @request.session[:user_id] = @user.id
  end

  def test_skip_digest_notification_shown
    get :account
    assert_response :success
    assert_tag :input,
               :attributes => { :name => 'pref[skip_digest_notifications]' }
  end

end
