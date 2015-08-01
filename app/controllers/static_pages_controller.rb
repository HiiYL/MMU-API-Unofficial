class StaticPagesController < ApplicationController
  def home
  	@bulletins = Bulletin.order(posted_on: :desc, url: :desc).limit(20)
  end

  def about
  end

  def contact
  end
end
