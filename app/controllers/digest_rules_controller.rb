class DigestRulesController < ApplicationController

  PREVIEW_ISSUE_LIMIT = 20

  before_filter :set_user

  def new
    @digest_rule = @user.digest_rules.build
  end

  def create
    @digest_rule = @user.digest_rules.build(params[:digest_rule])
    if @digest_rule.save
      redirect_to controller: 'my', action: 'account'
    else
      render action: 'new'
    end
  end

  def edit
    @digest_rule = DigestRule.find(params[:id])
  end

  def update
    @digest_rule = DigestRule.find(params[:id])
    if @digest_rule.update_attributes(params[:digest_rule])
      redirect_to controller: 'my', action: 'account'
    else
      render action: 'edit'
    end
  end

  def destroy
    digest_rule = DigestRule.find(params[:id])
    digest_rule.destroy
    redirect_to controller: 'my', action: 'account'
  end

  def show
    digest_rule = @user.digest_rules.find(params[:id])
    @digest     = RedmineDigest::Digest.new(digest_rule, Time.now, PREVIEW_ISSUE_LIMIT)
    render layout: 'digest'
  end

  private

  def set_user
    @user = User.current
  end
end
