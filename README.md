# Galileo Cloud Compass Pricing File "Get" Utility

Used to create the `azure.json` and `aws.json` pricing files for the GCC product.

The production destination for these 2 files is in the directory identified by:

```ruby
GCC_PRICING_DIR = Galileo.config[:ui]['gcc']['pricing']
```

This location is `<gpe-server-home>/ui/lib/galileo/visualizations/src/gcc/pricing`.

## Installation

Simpley clone the repo to run this standalone:

```bash
git clone git@codebox.galileosuite.com:galileo/gpe-gcc-pricing.git
cd gpe-gcc-pricing
bundle install --local
mkdir gcc-files
bundle exec gpe-gcc-pricing -o gcc-files
```

Or you can use the gem directly, add this line to your application's Gemfile.
(this will vary based on where you fetch this from)

```ruby
gem 'gpe-gcc-pricing', :git => "git@codebox.galileosuite.com:galileo/gpe-gcc-pricing.git"
```

And then execute:

    $ bundle install

Or install it yourself as to local:

    $ gem install ~/gpe-gcc-pricing-1.0.0.gem

Or install it yourself to the default gem location:

    $ gem install ~/gpe-gcc-pricing-1.0.0.gem --install-dir <you-local-path-here>

## Usage

Envoke with or without the `-o output_directory` option. The default is the current
location: `./gcc`.

If the `-o <output_directory>` does not exist then you will need to create it before this is run.

```ruby
bundle exec gpe-gcc-pricing [ -o <output_directory> ] 

# or

rm -rf ~/gcc && mkdir ~/gcc && bundle exec gpe-gcc-pricing -o ~/gcc
```

Or to update the files in place for production you can run this as follows (gpe-server-home must be gpe-server root)

```bash
 bundle exec gpe-gcc-pricing -o gpe-server-home/ui/lib/galileo/visualizations/src/gcc/pricing/
```

