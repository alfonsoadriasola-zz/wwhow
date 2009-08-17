require 'net/http'
require 'uri'

class Subscription < ActiveRecord::Base
  belongs_to :user
end
