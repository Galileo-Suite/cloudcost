module Cloudcost

  VERSION = "1.1.0"

  SAMPLE_CONFIG = %Q(
---

# Azure client ID and Secret
AZURE_CLIENTID: "xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
AZURE_CLIENTSECRET: "xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"


# https://portal.azure.com/#blade/Microsoft_Azure_GTM/ModernBillingMenuBlade/Overview
AZURE_SUBSCRIPTION: "xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Overview
AZURE_TENENT: "xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# We will collect all us locations but when building the price
# in the azure_build_price_file.rb script we will only get
# eastus data. Uncomment others locations for more.
AZURE_LOCATIONS:
  eastus: "US East"
  # westus: "US West"
  # centralus: "US Central"
  # eastus2: "US East 2"
  # westus2: "US West 2"
  # northcentralus: "US North Central"
  # southcentralus: "US South Central"
  # westcentralus: "US West Central"
)

end