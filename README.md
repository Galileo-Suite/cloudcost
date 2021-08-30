# Galileo Cloud Compass Pricing File "Get" Utility

Used to create the `azure.json` and `aws.json` pricing files for the GCC product.

The production destination for these 2 files in the directory identified by:

```ruby
GCC_PRICING_DIR = Galileo.config[:ui]['gcc']['pricing']
```

In production this would be `ui/lib/galileo/visualizations/src/gcc/pricing`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gpe-gcc-pricing'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install gpe-gcc-pricing

## Usage

Envoke with or without the `-o output_directory` option. The default is the current
location: `./gcc`.

If `-o` does not exist then you will need to create it.

```ruby
bundle exec gpe-gcc-pricing [ -o <output_directory> ] 

# or

rm -rf ~/gcc && mkdir ~/gcc && bundle exec gpe-gcc-pricing -o ~/gcc
```

Or to update the files in place for production you can run this as follows (gpe-server-home must be gpe-server root)

```bash
 bundle exec gpe-gcc-pricing -o gpe-server-home/ui/lib/galileo/visualizations/src/gcc/pricing/
```

