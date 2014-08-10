require 'fog'
require 'dotenv'

Dotenv.load unless ENV['VCLOUD_DIRECTOR_USERNAME']


conn = Fog::Compute::VcloudDirector.new(
  :vcloud_director_username => ENV['VCLOUD_DIRECTOR_USERNAME'],
  :vcloud_director_password => ENV['VCLOUD_DIRECTOR_PASSWORD'],
  :vcloud_director_host => ENV['VCLOUD_DIRECTOR_HOST'],
  :vcloud_director_api_version => '5.6')

# connect to the virtual data center (vdc)
vdc = conn.organizations.first.vdcs.first
org = conn.organizations.first
public_catalog = conn.organizations.first.catalogs.last
net = conn.organizations.first.networks.last

vname = 'dev-6859186912545709-VApp'
vapp_good = vdc.vapps.get_by_name(vname)
vm_good = vdc.vapps.get_by_name(vname).vms.first
vm_good.network
vapp_good.network_config

# vname = 'vname01'
# vapp_bad = vdc.vapps.get_by_name(vname)
# vm_bad = vdc.vapps.get_by_name(vname).vms.first
# vm_bad.network
# vapp_bad.network_config
# vapp1.network_config == vapp_good.network_config

# create new system (just like a physical system was built for you)
# 
vname = 'vdemo8' + rand.to_s
#template = public_catalog.catalog_items.get_by_name('Ubuntu Server 12.04 LTS (amd64 20140619)')
template = public_catalog.catalog_items.get_by_name('CentOS64-64bit')
net = conn.organizations.first.networks.find { |n| n if n.name.match("routed$")  }
template.instantiate(vname, vdc_id: vdc.id, network_id: net.id, description: vname + ' Desc')
vapp_new = vdc.vapps.get_by_name(vname)
vm_new = vapp_new.vms.first

# Define network connection for vm based on existing routed network
network_config = vapp_new.network_config.find { |n| n if n[:networkName].match("routed$") }
networks_config = [network_config]

# networks_config = vapp_new.network_config
section = {PrimaryNetworkConnectionIndex: 0}
section[:NetworkConnection] = networks_config.compact.each_with_index.map do |network, i|
  connection = {
    network: network[:networkName],
    needsCustomization: true,
    NetworkConnectionIndex: i,
    IsConnected: true
  }
  ip_address      = network[:ip_address]
  #allocation_mode = network[:allocation_mode]
  #allocation_mode = 'manual' if ip_address
  #allocation_mode = 'dhcp' unless %w{dhcp manual pool}.include?(allocation_mode)
  #allocation_mode = 'POOL'
  allocation_mode = 'pool'
  connection[:IpAddressAllocationMode] = allocation_mode.upcase
  connection[:IpAddress] = ip_address if ip_address
  connection
end

puts section

## have the junior sysadmin go setup the network connections like we defined above
nc_task = conn.put_network_connection_system_section_vapp(vm_new.id,section).body
conn.process_task(nc_task)

# [153] pry(main)> section
# => {:PrimaryNetworkConnectionIndex=>0,
#  :NetworkConnection=>
#   [{:network=>"M511664989-4904-default-routed", :needsCustomization=>true, :NetworkConnectionIndex=>0, :IsConnected=>true, :IpAddressAllocationMode=>"POOL"},
#    {:network=>"none", :needsCustomization=>true, :NetworkConnectionIndex=>1, :IsConnected=>true, :IpAddressAllocationMode=>"POOL"}]}
 ## put_guest_customization_section_vapp

## Must be done before first power on. Monkeys can't go edit the Linux box later
##
c=vm_new.customization
#c.admin_password_auto = false # auto
# c.admin_password_auto = true # auto
#c.admin_password = ENV['VCLOUD_VM_ADMIN_PASSWORD']
c.reset_password_required = false
c.customization_script = "sed -ibak 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config"
#c.script = 'date > /tmp/bootlog ` ; echo custom boot >> /tmp/bootlog`'
c.computer_name = 'DEV-' + Time.now.to_s.gsub(" ","_")

c.save

# power up box for the first time.
vm_new.power_on

# Refresh attributes for vm object to look at in IRB
vm_new.reload

vm_new.network
vm_new.customization.admin_password
vm_new.status
vm_new.ip_address
vm_new.customization.admin_password
