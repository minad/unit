# encoding: utf-8
require 'yaml'

class Numeric
  def to_unit
    Unit.new(self, 1)
  end

  def method_missing(name)
    Unit.method_name_to_unit(name).to_unit * self
  end

  def unit(unit)
    unit.to_unit * self
  end
end

class Rational
  def to_unit
    Unit.new(numerator, denominator)
  end
end

class String
  def to_unit
    Unit.new(1, 1, self)
  end
end

class Array
  def to_unit
    Unit.new(1, 1, self)
  end
end

class Unit < Numeric
  attr_reader :numerator, :denominator, :unit, :normalized

  def initialize(numerator,  denominator, unit = [])
    @numerator = numerator
    @denominator = denominator
    @unit = String === unit ? Unit.parse_unit(unit) : unit
    @normalized = nil
    reduce!
  end

  def initialize_copy(other)
    @numerator = other.numerator
    @denominator = other.denominator
    @unit = other.unit
    @normalized = other.normalized
  end

  def normalize
    @normalized ||= dup.normalize!
  end

  def normalize!
    if @normalized != self
      begin
        last_unit = @unit
        @unit = []
        last_unit.each do |prefix, unit, exp|
          if prefix != :one
            if exp >= 0
              @numerator *= PREFIXES[prefix][:base] ** (PREFIXES[prefix][:exp] * exp)
            else
              @denominator *= PREFIXES[prefix][:base] ** (PREFIXES[prefix][:exp] * -exp)
            end
          end
          if UNITS.key?(unit)
            @unit += Unit.power_unit(UNITS[unit][:def], exp)
          else
            @unit << [:one, unit, exp]
          end
        end
      end while last_unit != @unit
      reduce!
      @normalized = self
    end
    self
  end

  def *(other)
    a, b = coerce(other)
    Unit.new(a.numerator * b.numerator, a.denominator * b.denominator, a.unit + b.unit)
  end

  def /(other)
    a, b = coerce(other)
    Unit.new(a.numerator * b.denominator, a.denominator * b.numerator, a.unit + Unit.power_unit(b.unit, -1))
  end

  def +(other)
    raise TypeError, 'Incompatible units' if !compatible?(other)
    a, b = coerce(other)
    a, b = a.normalize, b.normalize
    Unit.new(a.numerator * b.denominator + b.numerator * a.denominator, a.denominator * b.denominator, a.unit).in(self)
  end

  def **(exp)
    raise TypeError if Unit === exp
    Unit.new(numerator ** exp, denominator ** exp, Unit.power_unit(unit, exp))
  end

  def -(other)
    self + (-other)
  end

  def -@
    Unit.new(-numerator, denominator, unit)
  end

  def ==(other)
    a, b = coerce(other)
    a, b = a.normalize, b.normalize
    a.numerator == b.numerator && a.denominator == b.denominator && a.unit == b.unit
  end

  def dimensionless?
    normalize.unit.empty?
  end

  alias unitless? dimensionless?

  def compatible?(other)
    a, b = coerce(other)
    a, b = a.normalize, b.normalize
    a.unit == b.unit
  end

  alias compatible_with? compatible?

  def in(unit)
    unit = unit.to_unit
    (self / unit).normalize * unit
  end

  def to_s
    s = ''
    s << @numerator.to_s
    s << "/#{@denominator}" if @denominator != 1
    positive = @unit.select {|prefix, name, exp| exp >= 0 }
    negative = @unit.select {|prefix, name, exp| exp < 0 }
    if positive.empty? && !negative.empty?
      s << ' 1'
    else
      s << ' ' << unit_string(positive)
    end
    if !negative.empty?
      s << '/' << unit_string(negative)
    end
    s
  end

  def to_i
    (@numerator / @denominator).to_i
  end

  def to_f
    @numerator.to_f / @denominator.to_f
  end

  def approx
    to_f.unit(unit)
  end

  def to_unit
    self
  end

  def coerce(val)
    raise TypeError, 'No unit support' if !val.respond_to? :to_unit
    [self, val.to_unit]
  end

  def method_missing(name)
    if name.to_s[0..2] == 'in_'
      self.in(Unit.method_name_to_unit(name))
    else
      super
    end
  end

  def self.method_name_to_unit(name)
    name.to_s.sub(/^in_/, '').sub(/^per_/, '1/').gsub('_per_', '/').gsub('_', ' ')
  end

  private

  def unit_string(list)
    units = []
    list.each do |prefix, name, exp|
      unit = ''
      unit << (PREFIXES[prefix] ? PREFIXES[prefix][:symbol] : prefix.to_s) if prefix != :one
      unit << (UNITS[name] ? UNITS[name][:symbol] : name.to_s)
      unit << '^' << exp.abs.to_s if exp.abs != 1
      units << unit
    end
    units.sort.join('·')
  end

  def self.power_unit(unit, pow)
    unit.map {|prefix, name, exp| [prefix, name, exp * pow] }
  end

  def reduce!
    # TODO: Gleiche Exponente, Prefixes kürzen

    # Gleiche Einheiten kürzen
    exponents = {}
    @unit.each do |prefix, unit, exp|
      exponents[prefix] ||= {}
      exponents[prefix][unit] ||= 0
      exponents[prefix][unit] += exp
    end
    @unit.clear
    exponents.each do |prefix, units|
      units.each do |unit, exp|
        @unit << [prefix, unit, exp] if exp != 0
      end
    end

    numbers = @unit.select {|prefix, unit, exp| Numeric === unit }
    @unit -= numbers
    numbers.each do |prefix, number, exp|
       if exp >= 0
         @numerator *= number ** exp
       else
         @denominator *= number ** -exp
       end
    end

    if Integer === @numerator && Integer === @denominator
      r = Rational(@numerator, @denominator)
      @numerator = r.numerator
      @denominator = r.denominator
    else
      @numerator /= @denominator
      @denominator = 1
    end

    if @numerator == 0
      @denominator = 1
      @unit.clear
    end

    @unit.sort!

    self
  end

  REAL   = /^(?:(?:\d*\.\d+|\d+\.\d*)(?:[eE][-+]?\d+)?|\d+[eE][-+]?\d+)$/
  DEC    = /^\d+$/
  SYMBOL = /^[a-zA-Z_][\w_]*$/
  OPERATOR = { '/' => ['/', 1], '*' => ['*', 1], '·' => ['*', 1], '^' => ['^', 2] }
  OPERATOR_TOKENS = OPERATOR.keys.map {|x| Regexp.quote(x) }
  VALUE_TOKENS = [REAL.source[1..-2], DEC.source[1..-2], SYMBOL.source[1..-2]]
  TOKENIZER = Regexp.new((OPERATOR_TOKENS + VALUE_TOKENS + ['\\(', '\\)']).join('|'))

  def self.lookup_symbol(symbol)
    if UNIT_SYMBOLS[symbol]
      [[:one, UNIT_SYMBOLS[symbol], 1]]
    else
      found = PREFIX_SYMBOLS.keys.find do |sym|
        symbol[0..sym.size-1] == sym && UNIT_SYMBOLS[symbol[sym.size..-1]]
      end
      [[PREFIX_SYMBOLS[found], UNIT_SYMBOLS[symbol[found.size..-1]], 1]] if found
    end
  end

  def self.symbol_to_unit(symbol)
    lookup_symbol(symbol) ||
    (symbol[-1..-1] == 's' ? lookup_symbol(symbol[0..-2]) : nil) || # Try english plural
    [[:one, symbol.to_sym, 1]]
  end

  def self.parse_unit(expr)
    stack, result = [], []
    implicit_mul = false
    expr.to_s.scan(TOKENIZER).each do |tok|
      if tok == '('
        stack << '('
        implicit_mul = false
      elsif tok == ')'
        compute(result, stack.pop) while !stack.empty? && stack.last != '('
        raise(SyntaxError, 'Unexpected token )') if stack.empty?
        stack.pop
        implicit_mul = true
      elsif OPERATOR.key?(tok)
        compute(result, stack.pop) while !stack.empty? && stack.last != '(' && OPERATOR[stack.last][1] >= OPERATOR[tok][1]
        stack << OPERATOR[tok][0]
        implicit_mul = false
      else
        val = case tok
              when REAL   then [[:one, tok.to_f, 1]]
              when DEC    then [[:one, tok.to_i, 1]]
              when SYMBOL then symbol_to_unit(tok)
              end
        if implicit_mul
          stack << '*'
          result << val
          compute(result, stack.pop)
        else
          result << val
          implicit_mul = true
        end
      end
    end
    compute(result, stack.pop) while !stack.empty?
    result.last
  end

  def self.compute(result, op)
    b = result.pop
    a = result.pop
    result << case op
              when '*' then a + b
              when '/' then a + power_unit(b, -1)
              when '^' then power_unit(a, b[0][1])
              else raise SyntaxError, "Unexpected token #{op}"
              end
  end

  def self.load_tables(file)
    data = YAML.load_file(file)

    data['prefixes'].each do |name, prefix|
      name = name.to_sym
      symbols = [prefix['sym']].flatten
      base = prefix['base']
      exp = prefix['exp']
      PREFIXES[name] = { :symbol => symbols.first, :exp => exp, :base => base }
      symbols.each { |sym| PREFIX_SYMBOLS[sym] = name }
      PREFIX_SYMBOLS[name.to_s] = name
    end

    data['units'].each do |name, unit|
      name = name.to_sym
      symbols = [unit['sym']].flatten
      UNITS[name] = { :symbol => symbols.first, :def => parse_unit(unit['def'])  }
      symbols.each { |sym| UNIT_SYMBOLS[sym] = name }
      UNIT_SYMBOLS[name.to_s] = name
    end
  end

  UNITS, UNIT_SYMBOLS, PREFIXES, PREFIX_SYMBOLS = {}, {}, {}, {}
  load_tables('units.yml')
end

def Unit(*args)
  if args.size == 3
    Unit.new(*args)
  elsif args.size == 2
    Unit.new(args[0], 1, args[1])
  elsif args.size == 1
    Unit.new(1, 1, args[0])
  else
    raise ArgumentError, 'wrong number of arguments'
  end
end

# Ruby 1.8
if !:test.respond_to? :<=>
  class Symbol
    include Comparable
    def <=>(other)
      self.to_i <=> other.to_i
    end
  end
end

