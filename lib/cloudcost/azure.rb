require 'awesome_print'
require 'json'
require 'benchmark'
require 'net/http'
require 'ostruct'

# {
#     "clientId": "56b8cf44-e5d8-465a-b551-468fb1f9b8ca",
#     "clientSecret": "uu8eXz6RsrjVfsSae4bS_7Y~qB3RsGZ_4o",
#     "subscriptionId": "345c9bee-914f-42e8-9600-77b3b10ba069",
#     "tenantId": "4376b3ca-4676-4ba7-8757-8b7fa5c43d83",
#     "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
#     "resourceManagerEndpointUrl": "https://management.azure.com/",
#     "activeDirectoryGraphResourceId": "https://graph.windows.net/",
#     "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
#     "galleryEndpointUrl": "https://gallery.azure.com/",
#     "managementEndpointUrl": "https://management.core.windows.net/"
# }

module Azure

    # CLIENTID        = "56b8cf44-e5d8-465a-b551-468fb1f9b8ca"
    # CLIENTSECRET    = "uu8eXz6RsrjVfsSae4bS_7Y~qB3RsGZ_4o"
    # SUBSCRIPTION    = "345c9bee-914f-42e8-9600-77b3b10ba069"   # https://portal.azure.com/#blade/Microsoft_Azure_GTM/ModernBillingMenuBlade/Overview
    # TENENT          = "4376b3ca-4676-4ba7-8757-8b7fa5c43d83"   # https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Overview

    # We will collect all us locations but when building the price
    # in the azure_build_price_file.rb script we will only get
    # eastus data.
    #Locations = {
        # "eastus"         => "US East",
        # "westus"         => "US West",
        # "centralus"      => "US Central",
        # "eastus2"        => "US East 2",
        # "westus2"        => "US West 2",
        # "northcentralus" => "US North Central",
        # "southcentralus" => "US South Central",
        # "westcentralus"  => "US West Central",
    # }
    
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

    def sku_cap_to_h(sku)
        ret = {}
        data = sku['capabilities']
        data.each do |h|
            ret.merge!({ h['name'] => h['value'] } )
        end
        return ret
    end

    def get_azure_auth()
        Log.info("Getting the Azure Access token.")
        uri = URI("https://login.microsoftonline.com/#{CFG['AZURE_TENENT']}/oauth2/token")
        res = Net::HTTP::post_form(uri, 
            {
                'grant_type' => "client_credentials",
                'resource' => "https://management.core.windows.net",
                'client_id' => CFG['AZURE_CLIENTID'],
                'client_secret' => CFG['AZURE_CLIENTSECRET'],
            }
        )
        return parse_response(res)['access_token']
    end

    def parse_response(res)
        if res.is_a?(Net::HTTPOK)
            Log.info("Request was successful.")
            return JSON.parse(res.body) 
        else
            body = JSON.parse(res.body)
            Log.error("Request returned an error: #{body['error']['message']}")
            exit 1
        end
        return nil
    end

    def get_sku_card_response(access_token)
        Log.info("Getting Azure SKU (product) list.")
        path = "https://management.azure.com/subscriptions/#{CFG['AZURE_SUBSCRIPTION']}/providers/Microsoft.Compute/skus?api-version=2016-08-31-preview&%24filter=OfferDurableId+eq+'MS-AZR-0003P'+and+Currency+eq+'USD'+and+Locale+eq+'en-US'+and+RegionInfo+eq+'US'"
        uri = URI(path)
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(uri)
        req.add_field("Authorization", "Bearer #{access_token}")
        res = http.request(req)
        return parse_response(res)
    end

    def translate_location(loc)
        Log.info("Translate location: #{loc}")
        loc = loc.to_s
        keys = CFG['AZURE_LOCATIONS'].keys
        vals = CFG['AZURE_LOCATIONS'].values
        k = keys.index(loc)
        v = vals.index(loc)
        return vals[k] unless k.nil?
        return keys[v] unless v.nil?
        return nil
    end

    def fetch_azure_data_from_web(service, location)
        Log.info("Request Azure '#{service}' pricing data for location '#{location}'.")
        uri = URI('https://prices.azure.com/api/retail/prices')
        params = { "$filter": "serviceName eq '#{service}' and armRegionName eq '#{location}'" }
        uri.query = URI.encode_www_form(params)
        data = get_pricing_pages(uri)
        return data
    end

    def get_pricing_pages(uri)
        ret = []
        more = true
        while more
            res = Net::HTTP.get_response(uri)
            if res.is_a?(Net::HTTPSuccess)
                resp = JSON.parse(res.body)
                uri = URI(resp['NextPageLink']) unless resp['NextPageLink'].nil?
                ret += resp['Items']
                break if resp['NextPageLink'].nil?
                Log.info("Total records so far: #{ret.length}")
            else
                more = false
            end
        end
        Log.info("Total records: #{ret.length}")
        return ret
    end    

    def get_azure_sku_card
        access_token = get_azure_auth()
        res = get_sku_card_response(access_token)
        return res['value']
        # File.open('skucard.json','w'){ |f| f << res.to_json }
    end

    def filter_sku_for_us_locations_and_vms_disks_only(sku)
        ret = sku.group_by do |x| 
            ['virtualMachines','disks'].include?(x["resourceType"]) && 
            CFG['AZURE_LOCATIONS'].keys.include?(x["locations"].first)
        end[true]
        return ret
    end

    def get_price_data_for(type)
        ret = []
        CFG['AZURE_LOCATIONS'].keys.each do |location| 
            ret += fetch_azure_data_from_web(type, location)
        end
        return ret
    end

    def azure_collect_and_build(output_dir)

        # Fetch and compile pricing for storage and vms
        storage = get_price_data_for('Storage')

        vms = get_price_data_for('Virtual Machines')

        # This is all the sku or product data limited to disks and vms
        skus = filter_sku_for_us_locations_and_vms_disks_only(get_azure_sku_card())
        skus.each{ |x| cap = sku_cap_to_h(x); x['capabilities'] = cap }

        # Get product from the sku file. Split by vms and disks (storage)
        eastus_skus_only            = skus.group_by{ |sku| sku['locations'].first }['eastus']
        skus_by_type                = eastus_skus_only.group_by{ |sku| sku['resourceType'] }
        vm_skus                     = skus_by_type['virtualMachines']
        storage_skus                = skus_by_type['disks']

        # VMs are a service id of "DZH313Z7MMC8"
        # Type of "Consumption", "Reservation", "DevTestConsumption"
        # productName e.g "Virtual Machines A Series Basic Windows",
        # skuName e.g "A0 Low Priority", Low Priority, 
        # armRegionName             => 'eastus'  (we don't use region for AWS. Can use it here right now.)
        vms_eastus_only             = vms.group_by{ |x| x['armRegionName'] == 'eastus' }[true]
        
        # Let's remove spot, Low or free versions
        vms_no_spot_or_low_priority = vms_eastus_only.group_by do |x| 
            x['skuName'].match(/(Low Priority|Spot)/i) or 
            x['meterName'].match?(/free/i) 
        end[false]

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

        outname = "#{output_dir}/azure.json"
        File.open(outname,'w'){ |f| f << vms_eastus_price_list.to_json }
        Log.info("Merging all Azure files to '#{outname}'")
    end

end;