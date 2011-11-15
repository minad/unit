# -*- coding: utf-8 -*-
require 'bacon'
require 'unit'
require 'unit/dsl'

describe "Errors" do
  describe "TypeError when adding incompatible units" do
    it "should have a nice error message" do
      a = Unit(1, "meter")
      b = Unit(1, "second")
      lambda do
        a + b
      end.should.raise(TypeError).message.should.equal("#{a.inspect} and #{b.inspect} are incompatible")
    end
  end

  describe "TypeError when trying to convert incompatible unit using #in!" do
    it "should have a nice error message" do
      unit = Unit(1000, "m / s")
      lambda do
        unit.in!("seconds")
      end.should.raise(TypeError).message.should.equal(%{Unexpected Unit("1000/1 m.s^-1"), expected to be in s})
      lambda do
        unit.in_seconds!
      end.should.raise(TypeError).message.should.equal(%{Unexpected Unit("1000/1 m.s^-1"), expected to be in s})
    end
  end
end
