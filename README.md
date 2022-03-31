# Cloud Cost Pricing Extract Utility

Used to create `azure.json` and `aws.json` pricing files using AWS and Azure 
pricing APIs (and additional magic).

## Prereqs

This script assumes:

* You already have been granted access to pricing data in both Azure and AWS
* AWS cli is configured locally
* You have Azure credentials you can provide in the .cloudcost config file.

## Installation

Simply clone the repo to run this standalone. Calling it like this will collect
both AWS and Azure pricing files to the users home directory. Use `--help` to get 
options or see below.

```bash
bundle install
bundle exec cloudcost
```

## Usage

The options are basic.

```bash
bundle exec cloudcost --help 
Options:
  -o, --output=<s>           Output Directory (default: .)
  -a, --azure, --no-azure    Get Azure Pricing (default: true)
  -w, --aws, --no-aws        Get AWS Pricing (default: true)
  -h, --help                 Show this message
```

# Pricing File Formats (AWS and Azure)

The AWS price file is caputred as-is and will remain intact.  It is not modified any way.

The Azure SKU and pricing data file from MS is merged together via this gem 
to more closely resemble the way the AWS pricing file is structured. It is an
array of product hashes. 

Each product hash in the array has the capabilties or characteristics of a compute or disk
product and attached is a list of product terms.  The systems can then besearched by the 
characteristics (CPU, Memory) and the pricing terms are associated.

Run the script and review a formated version of the `aws.json` and `azure.json` files 
outputed by this code to get more familiar with the contents.

Once you see the files live the data will make more sense.

## Azure and AWS Authentication

It's important to understand that this utility **REQUIRES** that vendor access and authentication 
are already configured and functioning on the local system.

### Azure

The authentication for Azure is pulled from a local config file in $HOME.
See the sample in configs for the format. The utility will put a sample file
in $HOME/.cloudcost.sample the first time executed if it's `.cloudcost` is not found.
That can be copied into place: `cp .cloudcost.sampe .cloudcost`

### AWS 

AWS requires that the local user that is running the script have the `$HOME/.aws` configurations
in place. Commands, like the following, should produce valid AWS repsonses from the system you intend
to run this script.

```bash
aws ec2 describe-instances
aws s3 ls
```
