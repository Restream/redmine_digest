require File.expand_path('../../test_helper', __FILE__)

class DigestRulesControllerTest < ActionController::TestCase
  fixtures :users, :user_preferences, :roles, :projects, :members, :member_roles,
           :issues, :issue_statuses, :trackers


  def setup
    @controller = DigestRulesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = User.find(1) # admin
    User.current = @user
    @request.session[:user_id] = @user.id
    @digest_rule = @user.digest_rules.create!(
        :name => 'testrule',
        :active => true,
        :project_selector => DigestRule::ALL,
        :recurrent => DigestRule::DAILY
    )
  end

  def test_get_new
    get :new
    assert_response :success
  end

  def test_post_create
    assert_difference 'DigestRule.count', 1 do
      post :create, :digest_rule => {
          :name => 'test',
          :active => true,
          :project_selector => DigestRule::ALL,
          :recurrent => DigestRule::DAILY }
    end

    assert_redirected_to '/my/account'
  end

  def test_get_edit
    get :edit, :id => @digest_rule.id
    assert_response :success
  end

  def test_put_update
    attrs = { :project_selector => DigestRule::MEMBER,
              :recurrent => DigestRule::MONTHLY }
    put :update, :id => @digest_rule.id, :digest_rule => attrs

    assert_redirected_to '/my/account'
    @digest_rule.reload
    assert_equal attrs[:project_selector], @digest_rule.project_selector
    assert_equal attrs[:recurrent], @digest_rule.recurrent
  end

  def test_post_destroy
    post :destroy, :id => @digest_rule.id

    assert_redirected_to '/my/account'
    digest_rule = DigestRule.find_by_id(@digest_rule.id)
    assert_nil digest_rule
  end

end
