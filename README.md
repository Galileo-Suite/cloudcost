# Galileo Cloud Compass Pricing File Utility

Used to create the azure.json and aws.json pricing files for the GCC product.

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

Envoke with or without the `-o output_directory` option. The default is `./gcc`.

If `-o` does not exist then you will need to create it.
```ruby
bundle exec gpe-gcc-pricing [ -o <output_directory> ] 
```

The best option is to create a new `--output` directory each time: 

```bash
rm -rf ~/gcc && mkdir ~/gcc && bundle exec gpe-gcc-pricing -o ~/gcc
```


