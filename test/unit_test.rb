# -*- coding: utf-8 -*-
require 'unit'
require 'unit/dsl'

Unit.default_system.load(:scientific)
Unit.default_system.load(:imperial)
Unit.default_system.load(:misc)

describe 'Unit' do
  it 'should support multiplication' do
    (Unit(2, 'm') * Unit(3, 'm')).should.equal Unit(6, 'm^2')
    (Unit(2, 'm') * 3).should.equal Unit(6, 'm')
    (Unit(2, 'm') * Rational(3, 4)).should.equal Unit(3, 2, 'm')
    (Unit(2, 'm') * 0.5).should.equal Unit(1.0, 'm')
  end

  it 'should support division' do
    (Unit(2, 'm') / Unit(3, 'm^2')).should.equal Unit(2, 3, '1/m')
    (Unit(2, 'm') / 3).should.equal Unit(2, 3, 'm')
    (Unit(2, 'm') / Rational(3, 4)).should.equal Unit(8, 3, 'm')
    (Unit(2, 'm') / 0.5).should.equal Unit(4.0, 'm')
  end

  it 'should support addition' do
    (Unit(42, 'm') + Unit(1, 'km')).should.equal Unit(1042, 'm')
    (Unit(1, 'm') - Unit(1, 'cm')).should.equal Unit(99, 100, 'm')
  end

  it 'should check unit compatiblity' do
    should.raise TypeError do
      (Unit(42, 'm') + Unit(1, 's'))
    end
    should.raise TypeError do
      (Unit(42, 'g') + Unit(1, 'm'))
    end
  end

  it 'should support exponentiation' do
    (Unit(2, 'm') ** 3).should.equal Unit(8, 'm^3')
    (Unit(9, 'm^2') ** 0.5).should.equal Unit(3.0, 'm')
    (Unit(9, 'm^2') ** Rational(1, 2)).should.equal Unit(3, 'm')
    (Unit(2, 'm') ** 1.3).should.equal Unit(2 ** 1.3, 'm^1.3')
  end

  it 'should not allow units as exponent' do
    should.raise TypeError do
      Unit(42, 'g') ** Unit(1, 'm')
    end
  end

  it 'should provide method sugar' do
    1.meter.should.equal Unit('1 meter')
    1.meter_per_second.should.equal Unit('1 m/s')
    1.meter.in_kilometer.should.equal Unit('1 m').in('km')
    1.unit('°C').should.equal Unit(1, '°C')
  end

  it 'should have a normalizer' do
    1.joule.normalize.should.equal Unit(1000, 'gram meter^2 / second^2')
    unit = 1.joule.normalize!
    unit.should.equal unit.normalized
  end

  it 'should convert units' do
    1.MeV.in_joule.should.equal Unit(1.602176487e-13, 'joule')
    1.kilometer.in_meter.should.equal Unit(1000, 'meter')
    1.liter.in('meter^3').should.equal Unit(1, 1000, 'meter^3')
    1.kilometer_per_hour.in_meter_per_second.should.equal Unit(5, 18, 'meter/second')
  end

  it 'should have a working compatible? method' do
    7.meter.compatible?('kilogram').should.equal false
    3.parsec.compatible_with?('meter').should.equal true
  end

  it 'should have a pretty string representation' do
    7.joule.normalize.to_s.should.equal '7000 g·m^2·s^-2'
  end

  it 'should parse units' do
    Unit(1, 'KiB s^-1').unit.should.equal [[:kibi, :byte, 1], [:one, :second, -1]].sort
    Unit(1, 'KiB/s').unit.should.equal [[:kibi, :byte, 1], [:one, :second, -1]].sort
    Unit(1, 'kilometer^2 / megaelectronvolt^7 * gram centiliter').unit.should.equal [[:kilo, :meter, 2], [:mega, :electronvolt, -7],
                                                                                     [:one, :gram, 1], [:centi, :liter, 1]].sort
  end

  it 'should reduce units' do
    1.joule_per_kilogram.normalize.unit.should.equal [[:one, :meter, 2], [:one, :second, -2]].sort
    1.megaton_per_kilometer.unit.should.equal [[:kilo, :ton, 1], [:one, :meter, -1]].sort
  end

  it 'should work with floating point values' do
    #w = (5.2).kilogram
    w = 5.2 * Unit('kilogram')
    w.in_pounds.to_int.should.equal 11
  end

  it 'should have dimensionless? method' do
    100.meter_per_km.should.be.dimensionless
    100.meter.per_km.should.be.dimensionless
    100.meter.per_km.should.be.unitless
    42.meter.per_second.should.not.be.unitless
    100.meter.per_km.should.equal Unit(Rational(1, 10))
  end

  it 'should be equal to rational if dimensionless' do
    100.meter.per_km.should.equal Rational(1, 10)
    100.meter.per_km.approx.should.equal 0.1
  end
end

