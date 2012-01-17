class Numeric
  def unit(unit, system = nil)
    Unit.to_unit(unit, system) * self
  end

  def method_missing(name, system = nil)
    Unit.to_unit(Unit.method_name_to_unit(name), system) * self
  end
end

class Unit < Numeric
  def self.method_name_to_unit(name)
    name.to_s.sub(/^per_/, '1/').gsub('_per_', '/').gsub('_', ' ')
  end

  def method_missing(name, system = nil)
    if name.to_s =~ /^in_(.*?)(!?)$/
      unit = Unit.method_name_to_unit($1)
      $2.empty? ? self.in(unit) : self.in!(unit)
    else
      super(name, system || @system)
    end
  end
end
