# encoding: utf-8
require 'si'

describe 'SI' do
  it 'should have si constructor' do
    (SI(2, 'm') ** 3).should.equal SI(8, 'm^3')
  end

  it 'should have si method' do
    1.si('°C').should.equal SI(1, '°C')
  end

  it 'should have to_si method' do
    :kelvin.to_si.should.equal SI('K')
  end
end
