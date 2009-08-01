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

  def sitemap
    @headers = {}
    @headers['Content-Type'] = "application/xml"
    @pages = [{:url => 'what/shoes/where/san francisco', :updated_at => Date.today },
              {:url => 'what/food/where/oakland', :updated_at => Date.today}]
    respond_to do |format|
      format.xml # sitemap.rxml
    end
  end
end
