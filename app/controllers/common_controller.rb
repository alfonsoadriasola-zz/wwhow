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
    prepare_tag_clouds
    render :action => '404'
  end

  def locations

  end
  
end
