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

  it "should return false from == for objects that are not comparable" do
    expect(Unit(1) == nil).to be false
    expect(Unit(1) == "string").to be false
    expect(Unit(1) == []).to be false
    expect(Unit(1) == :symbol).to be false
    expect(Unit(1)).not_to eq(nil)
    expect(Unit(1)).not_to eq("string")
  end

  it "should treat != consistently with ==" do
    expect(Unit(1) != nil).to be true
    expect(Unit(1) != "string").to be true
  end

  it "should return nil from <=> for objects that are not comparable" do
    expect(Unit(1) <=> nil).to be_nil
    expect(Unit(1) <=> "string").to be_nil
  end

  it "should raise ArgumentError for ordered comparison with incomparable objects" do
    expect { Unit(1) > nil }.to raise_error(ArgumentError)
    expect { Unit(1) < "string" }.to raise_error(ArgumentError)
  end

  it "should raise a descriptive ArgumentError from <=> for incompatible dimensions" do
    expect { Unit(1, 'm') <=> Unit(1, 's') }.to raise_error(
      ArgumentError, 'comparison of Unit("1 m") with Unit("1 s") failed'
    )
    expect { Unit(1, 'g') <=> Unit(1, 'm') }.to raise_error(ArgumentError)
  end

  it "should show the operand's class, not a coerced unit, for non-Unit numerics" do
    expect { Unit(1, 'm') > 1.2 }.to raise_error(
      ArgumentError, 'comparison of Unit("1 m") with Float failed'
    )
    expect { Unit(1, 'm') > 5 }.to raise_error(
      ArgumentError, 'comparison of Unit("1 m") with Integer failed'
    )
  end

  it "should label operands symmetrically when the unit is on the right" do
    expect { 1.2 > Unit(1, 'm') }.to raise_error(
      ArgumentError, 'comparison of Float with Unit("1 m") failed'
    )
    expect { 5 < Unit(1, 'm') }.to raise_error(
      ArgumentError, 'comparison of Integer with Unit("1 m") failed'
    )
  end

  it "should still compare units with compatible dimensions" do
    expect(Unit(100, 'cm') <=> Unit(1, 'm')).to eq(0)
    expect(Unit(1, 'cm') <=> Unit(1, 'm')).to eq(-1)
    expect(Unit(2, 'm') <=> Unit(1, 'm')).to eq(1)
  end

  it "should carry the descriptive error through every comparison path" do
    expect { Unit(1, 'm') > Unit(1, 's') }.to raise_error(ArgumentError, /Unit\("1 m"\).*Unit\("1 s"\)/)
    expect { [Unit(1, 'm'), Unit(2, 's')].sort }.to raise_error(ArgumentError, /incompatible|failed/)
    expect { Unit(1, 'm').between?(Unit(1, 's'), Unit(2, 's')) }.to raise_error(ArgumentError)
    expect { Unit(1, 'm').clamp(Unit(1, 's'), Unit(2, 's')) }.to raise_error(ArgumentError)
  end

  it "should sort and aggregate compatible units" do
    sorted = [Unit(3, 'm'), Unit(1, 'm'), Unit(2, 'm')].sort
    expect(sorted).to eq([Unit(1, 'm'), Unit(2, 'm'), Unit(3, 'm')])
    expect([Unit(50, 'cm'), Unit(1, 'm')].max).to eq(Unit(1, 'm'))
  end

  it "should support eql comparison" do
    expect(Unit(1)).to eql(Unit(1))
    expect(Unit(1.0)).not_to eql(Unit(1))

    expect(Unit(1)).not_to eql(UnitOne.new)
    expect(Unit(1.0)).not_to eql(UnitOne.new)
  end

  describe "#hash" do
    it "satisfies the eql?/hash contract: equal units have identical hash codes" do
      expect(Unit(1, 'm').hash).to eq(Unit(1, 'm').hash)
      expect(Unit(1).hash).to eq(Unit(1).hash)
      expect(Unit(Rational(1, 2), 'm').hash).to eq(Unit(Rational(1, 2), 'm').hash)
      expect(Unit(1.5, 'm').hash).to eq(Unit(1.5, 'm').hash)
    end

    it "is usable as a Hash key" do
      h = {}
      h[Unit(1, 'm')] = 'one meter'
      expect(h[Unit(1, 'm')]).to eq('one meter')
    end

    it "is usable in a Set" do
      require 'set'
      s = Set.new([Unit(1, 'm'), Unit(2, 'm'), Unit(1, 'm')])
      expect(s.size).to eq(2)
      expect(s).to include(Unit(1, 'm'))
    end

    it "differs for units that are not eql?" do
      expect(Unit(1, 'm').hash).not_to eq(Unit(2, 'm').hash)
      expect(Unit(1, 'm').hash).not_to eq(Unit(1, 's').hash)
      expect(Unit(1, 'm').hash).not_to eq(Unit(1.0, 'm').hash)
    end
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

  describe "#dup" do
    it "returns a distinct, independent copy" do
      unit = Unit(1, 'joule')

      copy = unit.dup
      expect(copy).not_to equal(unit)

      copy.normalize!
      expect(unit).to eql Unit(1, 'joule')
    end
  end

  describe "#freeze" do
    it "allows >= comparison without raising FrozenError" do
      expect(Unit(1, "m").freeze >= Unit("0.9 m")).to be true
    end

    it "allows < comparison without raising FrozenError" do
      expect(Unit(60, "Hz").freeze < Unit("61 Hz")).to be true
    end

    it "allows == comparison without raising FrozenError" do
      expect(Unit(1, "kg").freeze == Unit("1 kg")).to be true
    end
  end

  it 'should convert units' do
    expect(Unit(1, "MeV").in("joule")).to eq(Unit(1.602176487e-13, 'joule'))
    expect(Unit(1, "kilometer").in("meter")).to eq(Unit(1000, 'meter'))
    expect(Unit(1, "liter").in('meter^3')).to eq(Unit(1, 1000, 'meter^3'))
    expect(Unit(1, "kilometer/hour").in("meter/second")).to eq(Unit(5, 18, 'meter/second'))
  end

  it 'should extract the bare value in a target unit' do
    expect(Unit(1, "kilometer").value_in("meter")).to eq(1000)
    expect(Unit(1, "kilometer/hour").value_in("meter/second")).to eq(Rational(5, 18))
  end

  it 'should raise when value_in is given an incompatible unit' do
    expect { Unit(1, "meter").value_in("second") }.to raise_error(TypeError)
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
    expect(w.in("pounds").value.to_i).to eq(11)
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

  it "should fail ordered comparison on differing units" do
    expect { Unit(1, "second") > Unit(1, "meter") }.to raise_error(ArgumentError)
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

    it "should support the half: keyword" do
      expect(Unit(2.5, "m").round(half: :up)).to eq(Unit(3, "m"))
      expect(Unit(2.5, "m").round(half: :down)).to eq(Unit(2, "m"))
      expect(Unit(2.5, "m").round(half: :even)).to eq(Unit(2, "m"))
      expect(Unit(3.5, "m").round(half: :even)).to eq(Unit(4, "m"))
    end
  end

  describe "#ceil" do
    it "should return a unit" do
      expect(Unit(2.3, "m").ceil).to eq(Unit(3, "m"))
      expect(Unit(-2.3, "m").ceil).to eq(Unit(-2, "m"))
      expect(Unit(1, "m").ceil).to eq(Unit(1, "m"))
    end

    it "should respect precision" do
      expect(Unit(2.731, "m").ceil(1)).to eq(Unit(2.8, "m"))
      expect(Unit(2.731, "m").ceil(2)).to eq(Unit(2.74, "m"))
      expect(Unit(23.1, "m").ceil(-1)).to eq(Unit(30, "m"))
    end
  end

  describe "#floor" do
    it "should return a unit" do
      expect(Unit(2.7, "m").floor).to eq(Unit(2, "m"))
      expect(Unit(-2.7, "m").floor).to eq(Unit(-3, "m"))
      expect(Unit(1, "m").floor).to eq(Unit(1, "m"))
    end

    it "should respect precision" do
      expect(Unit(2.739, "m").floor(1)).to eq(Unit(2.7, "m"))
      expect(Unit(2.739, "m").floor(2)).to eq(Unit(2.73, "m"))
      expect(Unit(27.9, "m").floor(-1)).to eq(Unit(20, "m"))
    end
  end

  describe "#truncate" do
    it "should return a unit" do
      expect(Unit(2.7, "m").truncate).to eq(Unit(2, "m"))
      expect(Unit(-2.7, "m").truncate).to eq(Unit(-2, "m"))
      expect(Unit(1, "m").truncate).to eq(Unit(1, "m"))
    end

    it "should respect precision" do
      expect(Unit(2.739, "m").truncate(1)).to eq(Unit(2.7, "m"))
      expect(Unit(2.739, "m").truncate(2)).to eq(Unit(2.73, "m"))
      expect(Unit(27.9, "m").truncate(-1)).to eq(Unit(20, "m"))
    end
  end

  describe "#div" do
    it "returns the floored integer quotient as a dimensionless unit for compatible units" do
      expect(Unit(7, "m").div(Unit(2, "m"))).to eq(Unit(3))
      expect(Unit(-7, "m").div(Unit(2, "m"))).to eq(Unit(-4))
    end

    it "returns a unit with the combined dimension for incompatible units" do
      expect(Unit(7, "m").div(Unit(2, "s"))).to eq(Unit(3, "m/s"))
    end

    it "preserves the unit when dividing by a plain number" do
      expect(Unit(7, "m").div(2)).to eq(Unit(3, "m"))
      expect(Unit(-7, "m").div(2)).to eq(Unit(-4, "m"))
    end
  end

  describe "#remainder" do
    it "returns the remainder with the sign of the dividend" do
      expect(Unit(11, "m").remainder(Unit(4, "m"))).to eq(Unit(3, "m"))
      expect(Unit(-11, "m").remainder(Unit(4, "m"))).to eq(Unit(-3, "m"))
      expect(Unit(11, "m").remainder(Unit(-4, "m"))).to eq(Unit(3, "m"))
      expect(Unit(-11, "m").remainder(Unit(-4, "m"))).to eq(Unit(-3, "m"))
    end

    it "returns zero when evenly divisible" do
      expect(Unit(12, "m").remainder(Unit(4, "m"))).to eq(Unit(0, "m"))
    end

    it "differs from modulo for negative values" do
      expect(Unit(-11, "m") % Unit(4, "m")).to eq(Unit(1, "m"))   # modulo: sign of divisor
      expect(Unit(-11, "m").remainder(Unit(4, "m"))).to eq(Unit(-3, "m")) # remainder: sign of dividend
    end
  end

  describe "#to_r" do
    it "converts a dimensionless unit to Rational" do
      expect(Unit(3).to_r).to eq(Rational(3))
      expect(Unit(Rational(3, 4)).to_r).to eq(Rational(3, 4))
      expect(Unit(1.5).to_r).to eq(Rational(3, 2))
    end

    it "raises RangeError for dimensional units" do
      expect { Unit(3, "m").to_r }.to raise_error(RangeError, /can't convert/)
      expect { Unit(1.5, "m/s").to_r }.to raise_error(RangeError)
    end
  end
  describe "#numerator" do
    it "returns the numerator of a dimensionless unit" do
      expect(Unit(3).numerator).to eq(3)
      expect(Unit(Rational(2, 3)).numerator).to eq(2)
      expect(Unit(3.5).numerator).to eq(7)
    end

    it "raises RangeError for dimensional units" do
      expect { Unit(3, "m").numerator }.to raise_error(RangeError)
    end
  end

  describe "#denominator" do
    it "returns the denominator of a dimensionless unit (always a positive Integer)" do
      expect(Unit(3).denominator).to eq(1)
      expect(Unit(Rational(2, 3)).denominator).to eq(3)
      expect(Unit(3.5).denominator).to eq(2)
    end

    it "raises RangeError for dimensional units" do
      expect { Unit(3, "m").denominator }.to raise_error(RangeError)
    end
  end

  describe "#positive?" do
    it "returns true when value is greater than 0" do
      expect(Unit(1, "m").positive?).to be true
      expect(Unit(0.1, "m").positive?).to be true
      expect(Unit(Rational(1, 3), "m").positive?).to be true
    end

    it "returns false when value is 0 or less" do
      expect(Unit(0, "m").positive?).to be false
      expect(Unit(-1, "m").positive?).to be false
    end
  end

  describe "#negative?" do
    it "returns true when value is less than 0" do
      expect(Unit(-1, "m").negative?).to be true
      expect(Unit(-0.1, "m").negative?).to be true
      expect(Unit(Rational(-1, 3), "m").negative?).to be true
    end

    it "returns false when value is 0 or greater" do
      expect(Unit(0, "m").negative?).to be false
      expect(Unit(1, "m").negative?).to be false
    end
  end

  describe "#finite?" do
    it "returns true for finite values" do
      expect(Unit(1, "m").finite?).to be true
      expect(Unit(0, "m").finite?).to be true
      expect(Unit(-1.5, "m").finite?).to be true
      expect(Unit(Rational(1, 3), "m").finite?).to be true
    end

    it "returns false for +Infinity" do
      expect(Unit(Float::INFINITY, "m").finite?).to be false
    end

    it "returns false for -Infinity" do
      expect(Unit(-Float::INFINITY, "m").finite?).to be false
    end
  end

  describe "#infinite?" do
    it "returns nil for finite values" do
      expect(Unit(1, "m").infinite?).to be_nil
      expect(Unit(0, "m").infinite?).to be_nil
      expect(Unit(-1.5, "m").infinite?).to be_nil
      expect(Unit(Rational(1, 3), "m").infinite?).to be_nil
    end

    it "returns 1 for +Infinity" do
      expect(Unit(Float::INFINITY, "m").infinite?).to eq(1)
    end

    it "returns -1 for -Infinity" do
      expect(Unit(-Float::INFINITY, "m").infinite?).to eq(-1)
    end
  end

  describe "#+@" do
    it "returns self" do
      u = Unit(3, "m")
      expect(+u).to eq(u)
    end
  end

  describe "#abs2" do
    it "returns the square of the value with the unit squared" do
      expect(Unit(3, "m").abs2).to eq(Unit(9, "m^2"))
      expect(Unit(-3, "m").abs2).to eq(Unit(9, "m^2"))
    end
  end

  describe "#nonzero?" do
    it "returns self when the value is non-zero" do
      u = Unit(3, "m")
      expect(u.nonzero?).to equal(u)
    end

    it "returns nil when the value is zero" do
      expect(Unit(0, "m").nonzero?).to be_nil
    end
  end

  describe "#integer?" do
    it "always returns false (Unit is not Integer)" do
      expect(Unit(1, "m").integer?).to be false
      expect(Unit(1).integer?).to be false
    end
  end

  describe "#real?" do
    it "returns true for a real-valued unit" do
      expect(Unit(1, "m").real?).to be true
      expect(Unit(1.5, "m").real?).to be true
      expect(Unit(Rational(1, 2), "m").real?).to be true
    end

    it "returns false for a complex-valued unit" do
      expect(Unit(Complex(0, 1), "ohm").real?).to be false
      expect(Unit(Complex(3, 4), "ohm").real?).to be false
    end
  end

  describe "#real" do
    it "returns self for a real-valued unit" do
      u = Unit(3, "m")
      expect(u.real).to equal(u)
    end

    it "returns the real part as a Unit for a complex-valued unit" do
      expect(Unit(Complex(3, 4), "ohm").real).to eq(Unit(3, "ohm"))
      expect(Unit(Complex(0, 1), "ohm").real).to eq(Unit(0, "ohm"))
    end
  end

  describe "#imag" do
    it "returns 0 for a real-valued unit" do
      expect(Unit(3, "m").imag).to eq(0)
    end

    it "returns the imaginary part as a Unit for a complex-valued unit" do
      expect(Unit(Complex(3, 4), "ohm").imag).to eq(Unit(4, "ohm"))
      expect(Unit(Complex(0, 1), "ohm").imag).to eq(Unit(1, "ohm"))
    end
  end

  describe "#conj" do
    it "returns self for a real-valued unit" do
      u = Unit(3, "m")
      expect(u.conj).to equal(u)
    end

    it "returns the complex conjugate with unit preserved" do
      expect(Unit(Complex(3, 4), "ohm").conj).to eq(Unit(Complex(3, -4), "ohm"))
      expect(Unit(Complex(0, 1), "ohm").conj).to eq(Unit(Complex(0, -1), "ohm"))
    end
  end

  describe "#rect" do
    it "returns [self, 0] for a real-valued unit" do
      u = Unit(3, "m")
      expect(u.rect).to eq([u, 0])
    end

    it "returns [real_unit, imag_unit] for a complex-valued unit" do
      u = Unit(Complex(3, 4), "ohm")
      expect(u.rect).to eq([Unit(3, "ohm"), Unit(4, "ohm")])
    end
  end

  describe "#modulo" do
    it "is an alias for %" do
      expect(Unit(7, "m").modulo(Unit(3, "m"))).to eq(Unit(7, "m") % Unit(3, "m"))
    end

    it "returns the modulus with the sign of the divisor" do
      expect(Unit(-7, "m") % Unit(3, "m")).to eq(Unit(2, "m"))
      expect(Unit(7, "m") % Unit(-3, "m")).to eq(Unit(-2, "m"))
    end
  end

  describe "#divmod" do
    it "returns [quotient, modulus] for compatible units" do
      q, r = Unit(7, "m").divmod(Unit(2, "m"))
      expect(q).to eq(Unit(3))
      expect(r).to eq(Unit(1, "m"))
    end

    it "satisfies the divmod identity: self == other * q + r" do
      dividend = Unit(7, "m")
      divisor  = Unit(2, "m")
      q, r = dividend.divmod(divisor)
      expect(divisor * q + r).to eq(dividend)
    end
  end

  describe "#fdiv" do
    it "returns a float-valued unit when dividing by a scalar" do
      expect(Unit(3, "m").fdiv(2)).to eq(Unit(1.5, "m"))
    end

    it "returns a dimensionless float unit for compatible units" do
      expect(Unit(3, "m").fdiv(Unit(2, "m"))).to eq(Unit(1.5))
    end

    it "preserves the combined dimension for incompatible units" do
      expect(Unit(3, "m").fdiv(Unit(2, "s"))).to eq(Unit(1.5, "m/s"))
    end
  end

  describe "#to_f" do
    it "returns the Float value for a dimensionless unit" do
      expect(Unit(3).to_f).to eq(3.0)
      expect(Unit(Rational(1, 4)).to_f).to eq(0.25)
    end

    it "raises RangeError for a dimensional unit" do
      expect { Unit(3, "m").to_f }.to raise_error(RangeError, /can't convert/)
    end
  end

  describe "#to_i" do
    it "returns the Integer value for a dimensionless unit" do
      expect(Unit(3).to_i).to eq(3)
      expect(Unit(2.9).to_i).to eq(2)
    end

    it "raises RangeError for a dimensional unit" do
      expect { Unit(3, "m").to_i }.to raise_error(RangeError, /can't convert/)
    end
  end

  describe "#to_int" do
    it "returns the Integer value for a dimensionless unit" do
      expect(Unit(3).to_int).to eq(3)
    end

    it "raises RangeError for a dimensional unit" do
      expect { Unit(2, "m").to_int }.to raise_error(RangeError, /can't convert/)
    end
  end

  describe "#between?" do
    it "returns true when self is between min and max (inclusive)" do
      expect(Unit(1, "m").between?(Unit(0, "m"), Unit(2, "m"))).to be true
      expect(Unit(0, "m").between?(Unit(0, "m"), Unit(2, "m"))).to be true
      expect(Unit(2, "m").between?(Unit(0, "m"), Unit(2, "m"))).to be true
    end

    it "returns false when self is outside the range" do
      expect(Unit(3, "m").between?(Unit(0, "m"), Unit(2, "m"))).to be false
    end
  end

  describe "#clamp" do
    it "returns self when within the range" do
      expect(Unit(1, "m").clamp(Unit(0, "m"), Unit(2, "m"))).to eq(Unit(1, "m"))
    end

    it "returns the minimum when below the range" do
      expect(Unit(-1, "m").clamp(Unit(0, "m"), Unit(2, "m"))).to eq(Unit(0, "m"))
    end

    it "returns the maximum when above the range" do
      expect(Unit(5, "m").clamp(Unit(0, "m"), Unit(2, "m"))).to eq(Unit(2, "m"))
    end

    it "accepts a Range argument" do
      expect(Unit(5, "m").clamp(Unit(0, "m")..Unit(2, "m"))).to eq(Unit(2, "m"))
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
