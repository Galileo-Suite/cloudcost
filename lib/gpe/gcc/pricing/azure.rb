require 'awesome_print'
require 'oj'
require 'json'
require 'benchmark'
require 'net/http'
require 'ostruct'
require 'logger'

module GPE; module GCC; module Pricing; module Azure

    Log = Logger.new(STDOUT)

    ClientId        = "56b8cf44-e5d8-465a-b551-468fb1f9b8ca"
    ClientSecret    = "AtQmhrrZoCQY1_xzanrWOg.CP11HBkk-p6"

    # We will collect all us locations but when building the price
    # in the azure_build_price_file.rb script we will only get
    # eastus data.
    Locations = {
        "eastus"         => "US East",
        # "westus"         => "US West",
        # "centralus"      => "US Central",
        # "eastus2"        => "US East 2",
        # "westus2"        => "US West 2",
        # "northcentralus" => "US North Central",
        # "southcentralus" => "US South Central",
        # "westcentralus"  => "US West Central",
    }

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
        uri = URI('https://login.microsoftonline.com/4376b3ca-4676-4ba7-8757-8b7fa5c43d83/oauth2/token')
        res = Net::HTTP::post_form(uri, 
            {
                'grant_type' => "client_credentials",
                'resource' => "https://management.core.windows.net",
                'client_id' => ClientId,
                'client_secret' => ClientSecret,
            }
        )
        return parse_response(res)['access_token']
    end

    def parse_response(res)
        if res.is_a?(Net::HTTPOK)
            Log.info("Request was successful.")
            return JSON.parse(res.body) 
        else
            Log.error('Request returned an error.')
        end
        return nil
    end

    def get_sku_card_response(access_token)
        Log.info("Getting Azure SKU (product) list.")
        path = "https://management.azure.com/subscriptions/f24e5c35-383a-484c-81e6-6fc19a0692d6/providers/Microsoft.Compute/skus?api-version=2016-08-31-preview&%24filter=OfferDurableId+eq+'MS-AZR-0003P'+and+Currency+eq+'USD'+and+Locale+eq+'en-US'+and+RegionInfo+eq+'US'"
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
        keys = Locations.keys
        vals = Locations.values
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
            Locations.keys.include?(x["locations"].first)
        end[true]
        return ret
    end

    def get_price_data_for(type)
        ret = []
        Locations.keys.each do |location| 
            ret += fetch_azure_data_from_web(type, location)
        end
        return ret
    end

    def save_all(storage,vms,skus,dir)
        Log.info("Saving data out to disk.")
        FileUtils.mkdir_p(dir)
        File.open("#{dir}/skus.json",'w'){ |f| f << skus.to_json }
        File.open("#{dir}/storage.json",'w'){ |f| f << storage.to_json }
        File.open("#{dir}/vms.json",'w'){ |f| f << vms.to_json }
    end

end; end; end; end