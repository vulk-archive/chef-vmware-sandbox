# NOTE: This code is for exploring vchs and not meant to be run as a whole script
#

require 'ruby_vcloud_sdk'
require 'dotenv'

Dotenv.load unless ENV['VCLOUD_URL']

  #'https://p3v11-vcd.vchs.vmware.com:443/cloud/org/M511664989-4904/',
#ENV['VCLOUD_URL']
#'https://p3v11-vcd.vchs.vmware.com:443/cloud/org/M511664989-4904/',
client = VCloudSdk::Client.new(
  'https://p3v11-vcd.vchs.vmware.com',
  ENV['VCLOUD_USERNAME'], ENV['VCLOUD_PASSWORD'])
