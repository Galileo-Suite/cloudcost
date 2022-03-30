require_relative 'lib/cloudcost/version'

Gem::Specification.new do |spec|
  spec.name          = "gpe-gcc-pricing"
  spec.version       = Cloudcost::VERSION
  spec.authors       = ["Rich Davis"]
  spec.email         = ["rdavis@galileosuite.com"]

  spec.summary       = %q{Collect pricing files AWS and Azure.}
  spec.description   = %q{
    Store the AWS princing file and the Azure ratecard and pricing file
    in the directory identified by the -o file.

    The Azure credentials are located in the script.

    The AWS must be configured locally.
  }
  spec.homepage      = "https://www.galileosuite.com"
  spec.license       = "EULA"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.7")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "optimist"
  spec.add_runtime_dependency "awesome_print"
  spec.add_runtime_dependency "aws-sdk-pricing"
end
