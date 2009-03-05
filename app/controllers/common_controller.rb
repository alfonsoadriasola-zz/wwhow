class CommonController < ApplicationController

  def help

  end

  def about

  end

  def tos

  end

  def privacy

  end


  def malformed
    render :action => '404'
  end
end
