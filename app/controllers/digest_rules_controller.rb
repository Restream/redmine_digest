class DigestRulesController < ApplicationController

  before_filter :set_user

  def new
    @digest_rule = @user.digest_rules.build
  end

  def create

  end

  def edit

  end

  def update

  end

  private

  def set_user
    @user = User.current
  end
end
