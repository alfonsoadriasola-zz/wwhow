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
    @pages = []
    @headers['Content-Type'] = "application/xml"

    BlogEntry.master_category_list.each{|c|
      BlogEntry.browse_locations.each{|l| @pages <<{:url => "what/#{c}/where/#{l}/", :updated_at => DateTime.new(Date.today.year, Date.today.month, 1) } unless c == " "  }}

    respond_to do |format|
      format.xml # sitemap.rxml
    end
  end
end
