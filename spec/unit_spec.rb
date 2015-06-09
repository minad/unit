# -*- coding: utf-8 -*-
require 'spec_helper'

Unit.default_system.load(:scientific)
Unit.default_system.load(:imperial)
Unit.default_system.load(:misc)

describe 'Unit' do
  it 'should support multiplication' do
    expect(Unit(2, 'm') * Unit(3, 'm')).to eq(Unit(6, 'm^2'))
    expect(Unit(2, 'm') * 3).to eq(Unit(6, 'm'))
    expect(Unit(2, 'm') * Rational(3, 4)).to eq(Unit(3, 2, 'm'))
    expect(Unit(2, 'm') * 0.5).to eq(Unit(1.0, 'm'))
  end

  it 'should support division' do
    expect(Unit(2, 'm') / Unit(3, 'm^2')).to eq(Unit(2, 3, '1/m'))
    expect(Unit(2, 'm') / 3).to eq(Unit(2, 3, 'm'))
    expect(Unit(2, 'm') / Rational(3, 4)).to eq(Unit(8, 3, 'm'))
    expect(Unit(2, 'm') / 0.5).to eq(Unit(4.0, 'm'))
  end

  it 'should support addition' do
    expect(Unit(42, 'm') + Unit(1, 'km')).to eq(Unit(1042, 'm'))
  end

  it 'should support subtraction' do
    expect(Unit(1, 'm') - Unit(1, 'cm')).to eq(Unit(99, 100, 'm'))
    expect(Unit(2, 'm') - Unit(1, 'm')).to eq(Unit(1, 'm'))
  end

  it "should support arithmetic with Integers when appropriate" do
    expect(1 + Unit(1)).to eq(Unit(2))
    expect(2 - Unit(1)).to eq(Unit(1))
    expect(Unit(2) - 1).to eq(Unit(1))
    expect(2 - Unit(-1)).to eq(Unit(3))
    expect(Unit(2) - -1).to eq(Unit(3))
  end

  it "should support arithmetic with other classes using #coerce" do
    expect(Unit(2) + UnitOne.new).to eq(Unit(3))
    expect(2 + UnitOne.new).to eq(3)
    expect(Unit(2) - UnitOne.new).to eq(Unit(1))
    expect(2 - UnitOne.new).to eq(1)
    expect(Unit(2) * UnitOne.new).to eq(Unit(2))
    expect(2 * UnitOne.new).to eq(2)
    expect(Unit(2) / UnitOne.new).to eq(Unit(2))
    expect(2 / UnitOne.new).to eq(2)

    expect(UnitOne.new + Unit(4)).to eq(Unit(5))
    expect(UnitOne.new + 4).to eq(5)
    expect(UnitOne.new - Unit(4)).to eq(Unit(-3))
    expect(UnitOne.new - 4).to eq(-3)
    expect(UnitOne.new * Unit(4)).to eq(Unit(4))
    expect(UnitOne.new * 4).to eq(4)
    expect(UnitOne.new / Unit(4)).to eq(Unit(1, 4))
    expect(UnitOne.new / 4).to eq(0)
  end

  it "should support logic with other classes using #coerce" do
    expect(Unit(1)).to eq(UnitOne.new)
    expect(Unit(2)).to be > UnitOne.new
  end

  it "should support eql comparison" do
    expect(Unit(1)).to eql(Unit(1))
    expect(Unit(1.0)).not_to eql(Unit(1))

    expect(Unit(1)).not_to eql(UnitOne.new)
    expect(Unit(1.0)).not_to eql(UnitOne.new)
  end

  it "should not support adding anything but numeric unless object is coerceable" do
    expect { Unit(1) + 'string'}.to raise_error(TypeError)
    expect { Unit(1) + []}.to raise_error(TypeError)
    expect { Unit(1) + :symbol }.to raise_error(TypeError)
    expect { Unit(1) + {}}.to raise_error(TypeError)
  end

  it "should support adding through zero" do
    expect(Unit(0, "m") + Unit(1, "m")).to eq(Unit(1, "m"))
    expect(Unit(1, "m") + Unit(-1, "m") + Unit(1, "m")).to eq(Unit(1, "m"))
  end

  it 'should check unit compatiblity' do
    expect {Unit(42, 'm') + Unit(1, 's')}.to raise_error(TypeError)
    expect {Unit(42, 'g') + Unit(1, 'm')}.to raise_error(TypeError)
    expect {Unit(0, 'g') + Unit(1, 'm')}.to raise_error(TypeError)
  end

  it 'should support exponentiation' do
    expect(Unit(2, 'm') ** 3).to eq(Unit(8, 'm^3'))
    expect(Unit(9, 'm^2') ** 0.5).to eq(Unit(3.0, 'm'))
    expect(Unit(9, 'm^2') ** Rational(1, 2)).to eq(Unit(3, 'm'))
    expect(Unit(2, 'm') ** 1.3).to eq(Unit(2 ** 1.3, 'm^1.3'))
  end

  it 'should not allow units as exponent' do
    expect { Unit(42, 'g') ** Unit(1, 'm') }.to raise_error(TypeError)
  end

  describe "#normalize" do
    it "should return a normalized unit" do
      unit = Unit(1, 'joule')
      normalized_unit =  Unit(1000, 'gram meter^2 / second^2')

      expect(unit.normalize).to eql normalized_unit
    end

    it "should not modify the receiver" do
      unit = Unit(1, 'joule')
      normalized_unit =  Unit(1000, 'gram meter^2 / second^2')

      unit.normalize
      expect(unit).not_to eql normalized_unit
    end
  end

  describe "#normalize!" do
    it "should return a normalized unit" do
      unit = Unit(1, 'joule')
      normalized_unit =  Unit(1000, 'gram meter^2 / second^2')

      expect(unit.normalize!).to eql normalized_unit
    end

    it "should modify the receiver" do
      unit = Unit(1, 'joule')
      normalized_unit =  Unit(1000, 'gram meter^2 / second^2')

      unit.normalize!
      expect(unit).to eql normalized_unit
    end
  end

  it 'should convert units' do
    expect(Unit(1, "MeV").in("joule")).to eq(Unit(1.602176487e-13, 'joule'))
    expect(Unit(1, "kilometer").in("meter")).to eq(Unit(1000, 'meter'))
    expect(Unit(1, "liter").in('meter^3')).to eq(Unit(1, 1000, 'meter^3'))
    expect(Unit(1, "kilometer/hour").in("meter/second")).to eq(Unit(5, 18, 'meter/second'))
  end

  it 'should have a working compatible? method' do
    expect(Unit(7, "meter").compatible?('kilogram')).to eq(false)
    expect(Unit(3, "parsec").compatible_with?('meter')).to eq(true)
  end

  it 'should have a pretty string representation' do
    expect(Unit(7, "joule").normalize.to_s).to eq('7000 g·m^2·s^-2')
  end

  it 'should have a pretty string representation after subtraction' do
    expect((Unit('5 cm') - Unit('1 cm')).to_s).to eq('4 cm')
  end

  describe "#value_string" do
    it 'should behave like to_s normally' do
      expect(Unit(1, "liter").send(:value_string)).to eq("1")
      expect(Unit(0.5, "parsec").send(:value_string)).to eq("0.5")
    end

    it 'should wrap fractions in parentheses' do
      expect(Unit(Rational(1, 2), "m").send(:value_string)).to eq("(1/2)")
    end

    it 'should show reduced fractions' do
      expect(Unit(Rational(16, 6), "m").send(:value_string)).to eq("(8/3)")
    end

    it 'should not show 1 in the denominator' do
      expect(Unit(Rational(1), "foot").send(:value_string)).to eq("1")
      expect(Unit(Rational(4, 1), "inch").send(:value_string)).to eq("4")
    end
  end

  it 'should support round trip through to_s' do
    expect(Unit(Unit('(1/2) cm').to_s)).to eq(Unit('(1/2) cm'))
  end

  it 'should parse units' do
    expect(Unit(1, 'KiB s^-1').unit).to eq([[:kibi, :byte, 1], [:one, :second, -1]].sort)
    expect(Unit(1, 'KiB/s').unit).to eq([[:kibi, :byte, 1], [:one, :second, -1]].sort)
    expect(Unit(1, 'kilometer^2 / megaelectronvolt^7 * gram centiliter').unit).to eq([[:kilo, :meter, 2], [:mega, :electronvolt, -7],
                                                                                     [:one, :gram, 1], [:centi, :liter, 1]].sort)
  end

  it 'should reduce units' do
    expect(Unit(1, "joule/kilogram").normalize.unit).to eq([[:one, :meter, 2], [:one, :second, -2]].sort)
    expect(Unit(1, "megaton/kilometer").unit).to eq([[:one, :meter, -1], [:kilo, :ton, 1]])
  end

  it 'should work with floating point values' do
    w = 5.2 * Unit('kilogram')
    expect(w.in("pounds").to_int).to eq(11)
  end

  it 'should have dimensionless? method' do
    expect(Unit(100, "m/km")).to be_dimensionless
    expect(Unit(42, "meter/second")).not_to be_unitless
    expect(Unit(100, "meter/km")).to eq(Unit(Rational(1, 10)))
  end

  it 'should be equal to rational if dimensionless' do
    expect(Unit(100, "meter/km")).to eq(Rational(1, 10))
    expect(Unit(100, "meter/km").approx).to eq(0.1)
  end

  it 'should be comparable' do
    expect(Unit(1, 'm')).to be < Unit(2, 'm')
    expect(Unit(1, 'm')).to be <= Unit(2, 'm')

    expect(Unit(1, 'm')).to be <= Unit(1, 'm')
    expect(Unit(1, 'm')).to be >= Unit(1, 'm')

    expect(Unit(1, 'm')).to be > Unit(0, 'm')
    expect(Unit(1, 'm')).to be >= Unit(0, 'm')

    expect(Unit(100, "m")).to be < Unit(1, "km")
    expect(Unit(100, "m")).to be > Unit(0.0001, "km")
  end

  it "should fail comparison on differing units" do
    expect { Unit(1, "second") > Unit(1, "meter") }.to raise_error(Unit::IncompatibleUnitError)
  end

  it "should keep units when the value is zero" do
    expect(Unit(0, "m").unit).to eq([[:one, :meter, 1]])
  end

  it "should support absolute value" do
    expect(Unit(1, "m").abs).to eq(Unit(1, "m"))
    expect(Unit(-1, "m").abs).to eq(Unit(1, "m"))
  end

  it "should have #zero?" do
    expect(Unit(0, "m").zero?).to eq(true)
    expect(Unit(1, "m").zero?).to eq(false)
  end

  it "should produce an approximation" do
    expect(Unit(Rational(1,3), "m").approx).to eq(Unit(1.0/3.0, "m"))
  end

  describe "#round" do
    it "should be able to round and return a unit" do
      expect(Unit(Rational(1,3), "m").round).to eq(Unit(0, "m"))
      expect(Unit(Rational(2,3), "m").round).to eq(Unit(1, "m"))
      expect(Unit(0.1, "m").round).to eq(Unit(0, "m"))
      expect(Unit(0.5, "m").round).to eq(Unit(1, "m"))
      expect(Unit(1, "m").round).to eq(Unit(1, "m"))
    end

    it "should respect rounding precision" do
      expect(Unit(0.1234, "m").round(0)).to eq(Unit(0, "m"))
      expect(Unit(1.2345, "m").round(1)).to eq(Unit(1.2, "m"))
      expect(Unit(5.4321, "m").round(2)).to eq(Unit(5.43, "m"))
    end
  end

end

describe "Unit DSL", dsl: true do
  it 'should provide method sugar' do
    expect(1.meter).to eq(Unit('1 meter'))
    expect(1.meter_per_second).to eq(Unit('1 m/s'))
    expect(1.meter.in_kilometer).to eq(Unit('1 m').in('km'))
    expect(1.unit('°C')).to eq(Unit(1, '°C'))
  end
end
