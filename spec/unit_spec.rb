# -*- coding: utf-8 -*-
require 'spec_helper'

Unit.default_system.load(:scientific)
Unit.default_system.load(:imperial)
Unit.default_system.load(:misc)

describe 'Unit' do
  it 'should support multiplication' do
    (Unit(2, 'm') * Unit(3, 'm')).should == Unit(6, 'm^2')
    (Unit(2, 'm') * 3).should == Unit(6, 'm')
    (Unit(2, 'm') * Rational(3, 4)).should == Unit(3, 2, 'm')
    (Unit(2, 'm') * 0.5).should == Unit(1.0, 'm')
  end

  it 'should support division' do
    (Unit(2, 'm') / Unit(3, 'm^2')).should == Unit(2, 3, '1/m')
    (Unit(2, 'm') / 3).should == Unit(2, 3, 'm')
    (Unit(2, 'm') / Rational(3, 4)).should == Unit(8, 3, 'm')
    (Unit(2, 'm') / 0.5).should == Unit(4.0, 'm')
  end

  it 'should support addition' do
    (Unit(42, 'm') + Unit(1, 'km')).should == Unit(1042, 'm')
  end

  it 'should support subtraction' do
    (Unit(1, 'm') - Unit(1, 'cm')).should == Unit(99, 100, 'm')
    (Unit(2, 'm') - Unit(1, 'm')).should == Unit(1, 'm')
  end

  it "should support arithmetic with Integers when appropriate" do
    (1 + Unit(1)).should == Unit(2)
    (2 - Unit(1)).should == Unit(1)
    (Unit(2) - 1).should == Unit(1)
    (2 - Unit(-1)).should == Unit(3)
    (Unit(2) - -1).should == Unit(3)
  end

  it "should support adding through zero" do
    (Unit(0, "m") + Unit(1, "m")).should == Unit(1, "m")
    (Unit(1, "m") + Unit(-1, "m") + Unit(1, "m")).should == Unit(1, "m")
  end

  it 'should check unit compatiblity' do
    lambda {Unit(42, 'm') + Unit(1, 's')}.should raise_error(TypeError)
    lambda {Unit(42, 'g') + Unit(1, 'm')}.should raise_error(TypeError)
    lambda {Unit(0, 'g') + Unit(1, 'm')}.should raise_error(TypeError)
  end

  it 'should support exponentiation' do
    (Unit(2, 'm') ** 3).should == Unit(8, 'm^3')
    (Unit(9, 'm^2') ** 0.5).should == Unit(3.0, 'm')
    (Unit(9, 'm^2') ** Rational(1, 2)).should == Unit(3, 'm')
    (Unit(2, 'm') ** 1.3).should == Unit(2 ** 1.3, 'm^1.3')
  end

  it 'should not allow units as exponent' do
    lambda {Unit(42, 'g') ** Unit(1, 'm')}.should raise_error(TypeError)
  end

  it 'should provide method sugar' do
    1.meter.should == Unit('1 meter')
    1.meter_per_second.should == Unit('1 m/s')
    1.meter.in_kilometer.should == Unit('1 m').in('km')
    1.unit('°C').should == Unit(1, '°C')
  end

  it 'should have a normalizer' do
    1.joule.normalize.should == Unit(1000, 'gram meter^2 / second^2')
    unit = 1.joule.normalize!
    unit.should == unit.normalized
  end

  it 'should convert units' do
    1.MeV.in_joule.should == Unit(1.602176487e-13, 'joule')
    1.kilometer.in_meter.should == Unit(1000, 'meter')
    1.liter.in('meter^3').should == Unit(1, 1000, 'meter^3')
    1.kilometer_per_hour.in_meter_per_second.should == Unit(5, 18, 'meter/second')
  end

  it 'should have a working compatible? method' do
    7.meter.compatible?('kilogram').should == false
    3.parsec.compatible_with?('meter').should == true
  end

  it 'should have a pretty string representation' do
    7.joule.normalize.to_s.should == '7000 g·m^2·s^-2'
  end

  it 'should parse units' do
    Unit(1, 'KiB s^-1').unit.should == [[:kibi, :byte, 1], [:one, :second, -1]].sort
    Unit(1, 'KiB/s').unit.should == [[:kibi, :byte, 1], [:one, :second, -1]].sort
    Unit(1, 'kilometer^2 / megaelectronvolt^7 * gram centiliter').unit.should == [[:kilo, :meter, 2], [:mega, :electronvolt, -7],
                                                                                     [:one, :gram, 1], [:centi, :liter, 1]].sort
  end

  it 'should reduce units' do
    1.joule_per_kilogram.normalize.unit.should == [[:one, :meter, 2], [:one, :second, -2]].sort
    1.megaton_per_kilometer.unit.should == [[:kilo, :ton, 1], [:one, :meter, -1]].sort
  end

  it 'should work with floating point values' do
    #w = (5.2).kilogram
    w = 5.2 * Unit('kilogram')
    w.in_pounds.to_int.should == 11
  end

  it 'should have dimensionless? method' do
    100.meter_per_km.should be_dimensionless
    100.meter.per_km.should be_dimensionless
    100.meter.per_km.should be_unitless
    42.meter.per_second.should_not be_unitless
    100.meter.per_km.should == Unit(Rational(1, 10))
  end

  it 'should be equal to rational if dimensionless' do
    100.meter.per_km.should == Rational(1, 10)
    100.meter.per_km.approx.should == 0.1
  end

  it 'should be comparable' do
    Unit(1,'m').should < Unit(2,'m')
    Unit(1,'m').should <= Unit(2,'m')

    Unit(1,'m').should <= Unit(1,'m')
    Unit(1,'m').should >= Unit(1,'m')

    Unit(1,'m').should > Unit(0,'m')
    Unit(1,'m').should >= Unit(0,'m')

    Unit(100, "m").should < Unit(1, "km")
    Unit(100, "m").should > Unit(0.0001, "km")
  end

  it "should fail comparison on differing units" do
    lambda do
      Unit(1, "second") > Unit(1, "meter")
    end.should raise_error(ArgumentError)
  end

  it "should keep units when the value is zero" do
    Unit(0, "m").unit.should == [[:one, :meter, 1]]
  end

  it "should support absolute value" do
    Unit(1, "m").abs.should == Unit(1, "m")
    Unit(-1, "m").abs.should == Unit(1, "m")
  end

  it "should have #zero?" do
    Unit(0, "m").zero?.should == true
    Unit(1, "m").zero?.should == false
  end

  it "should produce an approximation" do
    Unit(Rational(1,3), "m").approx.should == Unit(1.0/3.0, "m")
  end
end
