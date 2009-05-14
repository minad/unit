# encoding: utf-8

require 'test/spec'
require 'units'

describe 'Unit' do
  it 'should provide method sugar' do
    1.meter.should.equal  Unit('1 meter')
    1.meter_per_second.should.equal  Unit('1 m/s')
    1.meter.in_kilometer.should.equal Unit('1 m').in('km')
    1.unit('°C').should.equal Unit(1, '°C')
  end

  it 'should reduce units' do
    (1.second_per_gram / 1.second).to_s.should.equal 1.per_gram.to_s
  end

  it 'should normalize units' do
    (1.newton * 1.unit('s^2')).should.equal 1.meter_kilogram
  end
end

