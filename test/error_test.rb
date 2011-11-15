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

  describe "TypeError when trying to convert incompatible unit using #in!" do
    it "should have a nice error message" do
      unit = Unit(1000, "m / s")
      new_unit = "seconds"
      lambda {
        unit.in!(new_unit)
      }.should.raise(TypeError).message.should.equal(%{Unexpected unit Unit("1000/1 m.s^-1"), expected to be in seconds})
    end
  end
end
