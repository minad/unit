def Unit(*args)
  value = Numeric === args.first ? args.shift : 1
  value = Rational(value, args.shift) if Numeric === args.first

  system = args.index {|x| Unit::System === x }
  system = system ? args.delete_at(system) : Unit.default_system

  unit = args.index {|x| String === x }
  unit = system.parse_unit(args.delete_at(unit)) if unit

  unless unit
    unit = args.index {|x| Array === x }
    unit = args.delete_at(unit) if unit
  end

  unit ||= []
  system.validate_unit(unit)

  raise ArgumentError, 'wrong number of arguments' unless args.empty?

  Unit.new(value, unit, system)
end
