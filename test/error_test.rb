# -*- coding: utf-8 -*-
require 'bacon'
require 'unit'
require 'unit/dsl'

describe "Errors" do
  describe "TypeError when adding incompatible units" do
    it "should have a nice error message" do
      unit_1 = Unit(1, "meter")
      unit_2 = Unit(1, "second")
      lambda {
        unit_1 + unit_2
      }.should.raise(TypeError).message.should.equal("Incompatible units: #{unit_1.inspect} and #{unit_2.inspect}")
    end
  end
end
