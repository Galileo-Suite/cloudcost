require 'json'
require 'awesome_print'

module GPE; module GCC; module Pricing; module Azure;

=begin

    Create the Azure price file: azure.json

    The purpose of this script is to reorganize the massive Azure sku and price files
    into a usable format for GCC.

    The azure.rb script must run before this and populate the cache dir from the MS 
    api calls.

    Sku file:
    - extract region eastus only (v1 8/2021)
    - sku split into storage and vm products

    VM Pricing Files
    - eastus only (v1 8/2021)
    - remove spot and low priority products
    - split by OS (windows or no)
    - attach to OnDemand (consumption)

=end

home                        = File.expand_path(File.dirname(__FILE__))
file_cache                  = File.join(home,'cache')

# Get product from the sku file. Split by vms and disks (storage)
skus                        = JSON.parse(File.open("#{file_cache}/skus.json",'r').read)
eastus_skus_only            = skus.group_by{ |sku| sku['locations'].first }['eastus']
skus_by_type                = eastus_skus_only.group_by{ |sku| sku['resourceType'] }
vm_skus                     = skus_by_type['virtualMachines']
storage_skus                = skus_by_type['disks']

# Get storage pricing
# Storage is serviceId of "DZH317F1HKN0"
# Type of "Consumption", "Reservation"
storage                     = JSON.parse(File.open("#{file_cache}/storage.json",'r').read)

# VMs are a service id of "DZH313Z7MMC8"
# Type of "Consumption", "Reservation", "DevTestConsumption"
# productName e.g "Virtual Machines A Series Basic Windows",
# skuName e.g "A0 Low Priority", Low Priority, 
# armRegionName             => 'eastus'  (we don't use region for AWS. Can use it here right now.)
vms                         = JSON.parse(File.open("#{file_cache}/vms.json",'r').read)
vms_eastus_only             = vms.group_by{ |x| x['armRegionName'] == 'eastus' }[true]
vms_no_spot_or_low_priority = vms_eastus_only.group_by{ |x| x['skuName'] =~ /(Low Priority|Spot)/i ? true : false }[false]

# Get ondemand / consumption pricing
vms_eastus_ondemand         = vms_no_spot_or_low_priority.group_by{ |x| x['type'] == 'Consumption' }[true]
vms_by_os                   = vms_eastus_ondemand.group_by{ |x| x['productName'] =~ /windows$/i ? true : false }
vms_windows                 = vms_by_os[true].group_by{ |x| x['armSkuName']}
vms_linux                   = vms_by_os[false].group_by{ |x| x['armSkuName']}

# Get reserved pricing
vms_eastus_res               = vms_no_spot_or_low_priority.group_by{ |x| x['type'] == 'Reservation' }[true];
vms_eastus_res_by_term       = vms_eastus_res.group_by{ |x| x['reservationTerm'] }
vms_eastus_res_1yr           = vms_eastus_res_by_term['1 Year'].group_by{ |x| x['armSkuName']}
vms_eastus_res_3yr           = vms_eastus_res_by_term['3 Years'].group_by{ |x| x['armSkuName']}
vms_eastus_res_5yr           = vms_eastus_res_by_term['5 Years'].group_by{ |x| x['armSkuName']}

def check_terms(terms)
    case 
    when terms.nil?
        return nil
    when terms.length != 1 
        raise 'too many terms found, there is something wrong. '
    else
        return terms.first
    end
end

vms_eastus_price_list = []
vm_skus.each do |sku|
    name = sku['name']
    sku['terms'] = {
        'OnDemand': {
            'windows': check_terms(vms_windows[name]),
            'linux': check_terms(vms_linux[name])
        },
        'Reserved': {
            '1year': check_terms(vms_eastus_res_1yr[name]),
            '3year': check_terms(vms_eastus_res_3yr[name]),
            '5year': check_terms(vms_eastus_res_5yr[name])
        }
    }
    vms_eastus_price_list << sku
end

require 'debug'
puts :HERE

File.open("#{file_cache}/azure.json",'w'){ |f| f << vms_eastus_price_list.to_json }

end; end; end; end