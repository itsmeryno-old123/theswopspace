class WelcomeController < ApplicationController
  def index
    @user = User.new
    @news = News.order("date DESC").all
  end
  
  def index2
    render :layout => false
  end
end
