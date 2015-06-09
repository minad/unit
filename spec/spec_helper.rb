require 'rspec'
require 'unit'
require './spec/support/unit_one'

RSpec.configure do |config|
  unless config.exclusion_filter[:dsl]
    config.before(:suite) do
      require 'unit/dsl'
    end
  end
end

