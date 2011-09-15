# encoding: utf-8
require 'yaml'

class Unit < Numeric
  VERSION = '0.2.1'

  attr_reader :numerator, :denominator, :unit, :normalized, :system

  def initialize(numerator, denominator, unit, system)
    @system = system
    @numerator = numerator
    @denominator = denominator
    @unit = unit.dup
    @normalized = nil
    reduce!
  end

  def initialize_copy(other)
    @system = other.system
    @numerator = other.numerator
    @denominator = other.denominator
    @unit = other.unit.dup
    @normalized = other.normalized
  end

  # Converts to base units
  def normalize
    @normalized ||= dup.normalize!
  end

  # Converts to base units
  def normalize!
    if @normalized != self
      begin
        last_unit = @unit
        @unit = []
        last_unit.each do |prefix, unit, exp|
          if prefix != :one
            if exp >= 0
              @numerator *= @system.prefix[prefix][:value] ** exp
            else
              @denominator *= @system.prefix[prefix][:value] ** -exp
            end
          end
          if @system.unit[unit]
            @unit += Unit.power_unit(@system.unit[unit][:def], exp)
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
    Unit.new(a.numerator * b.numerator, a.denominator * b.denominator, a.unit + b.unit, system)
  end

  def /(other)
    a, b = coerce(other)
    Unit.new(a.numerator * b.denominator, a.denominator * b.numerator, a.unit + Unit.power_unit(b.unit, -1), system)
  end

  def +(other)
    raise TypeError, 'Incompatible units' if !compatible?(other)
    a, b = coerce(other)
    a, b = a.normalize, b.normalize
    Unit.new(a.numerator * b.denominator + b.numerator * a.denominator, a.denominator * b.denominator, a.unit, system).in(self)
  end

  def **(exp)
    raise TypeError if Unit === exp
    Unit.new(numerator ** exp, denominator ** exp, Unit.power_unit(unit, exp), system)
  end

  def -(other)
    self + (-other)
  end

  def -@
    Unit.new(-numerator, denominator, unit, system)
  end

  def ==(other)
    a, b = coerce(other)
    a, b = a.normalize, b.normalize
    a.numerator == b.numerator && a.denominator == b.denominator && a.unit == b.unit
  end

  # Number without dimension
  def dimensionless?
    normalize.unit.empty?
  end

  alias unitless? dimensionless?

  # Compatible units can be added
  def compatible?(other)
    a, b = coerce(other)
    a, b = a.normalize, b.normalize
    (a.unit == b.unit) || (a == 0 || b == 0)
  end

  alias compatible_with? compatible?

  # Convert to other unit
  def in(unit)
    unit = unit.to_unit(system)
    (self / unit).normalize * unit
  end

  def inspect
    unit.empty? ? %{Unit("#{number_string}")} : %{Unit("#{number_string} #{unit_string('.')}")}
  end

  def to_s
    unit.empty? ? number_string : "#{number_string} #{unit_string('·')}"
  end

  def to_tex
    unit.empty? ? number_string : "\SI{#{number_string}}{#{unit_string('.')}}"
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

  def to_unit(system = nil)
    system ||= Unit.default_system
    raise TypeError, 'Different unit system' if @system != system
    self
  end

  def coerce(val)
    raise TypeError, 'No unit support' if !val.respond_to? :to_unit
    [self, val.to_unit(system)]
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

  def number_string
    @numerator.to_s << (@denominator == 1 ? '' : "/#{@denominator}")
  end

  def unit_string(sep)
    (unit_list(@unit.select {|prefix, name, exp| exp >= 0 }) +
     unit_list(@unit.select {|prefix, name, exp| exp < 0 })).join(sep)
  end

  def unit_list(list)
    units = []
    list.each do |prefix, name, exp|
      unit = ''
      unit << (@system.prefix[prefix] ? @system.prefix[prefix][:symbol] : prefix.to_s) if prefix != :one
      unit << (@system.unit[name] ? @system.unit[name][:symbol] : name.to_s)
      unit << '^' << exp.to_s if exp != 1
      units << unit
    end
    units.sort
  end

  def self.power_unit(unit, pow)
    unit.map {|prefix, name, exp| [prefix, name, exp * pow] }
  end

  # Reduce units and prefixes
  def reduce!
    # Remove numbers from units
    numbers = @unit.select {|prefix, unit, exp| Numeric === unit }
    @unit -= numbers
    numbers.each do |prefix, number, exp|
       raise RuntimeError, 'Numeric unit with prefix' if prefix != :one
       if exp >= 0
         @numerator *= number ** exp
       else
         @denominator *= number ** -exp
       end
    end

    # Reduce number
    if Integer === @numerator && Integer === @denominator
      r = Rational(@numerator, @denominator)
      @numerator = r.numerator
      @denominator = r.denominator
    else
      r = @numerator / @denominator
      if Rational === r
        @numerator = r.numerator
        @denominator = r.denominator
      else
        @numerator = r
        @denominator = 1
      end
    end

    if @numerator == 0
      @denominator = 1
      @unit.clear
    end

    # Reduce units
    @unit.sort!
    i, current = 1, 0
    while i < @unit.size do
      while i < @unit.size && @unit[current][0] == @unit[i][0] && @unit[current][1] == @unit[i][1]
        @unit[current] = @unit[current].dup
        @unit[current][2] += @unit[i][2]
        i += 1
      end
      if @unit[current][2] == 0
        @unit.slice!(current, i - current)
      else
        @unit.slice!(current + 1, i - current - 1)
        current += 1
      end
      i = current + 1
    end

    # Reduce prefixes
    @unit.each_with_index do |(prefix1, unit1, exp1), k|
      next if exp1 < 0
      @unit.each_with_index do |(prefix2, unit2, exp2), j|
        if exp2 < 0 && exp2 == -exp1
          q, r = @system.prefix[prefix1][:value].divmod @system.prefix[prefix2][:value]
          if r == 0 && new_prefix = @system.prefix_value[q]
            @unit[k] = @unit[k].dup
            @unit[j] = @unit[j].dup
            @unit[k][0] = new_prefix
            @unit[j][0] = :one
          end
        end
      end
    end

    self
  end

  public

  class System
    attr_reader :name, :unit, :unit_symbol, :prefix, :prefix_symbol, :prefix_value

    def initialize(name, &block)
      @name = name
      @unit = {}
      @unit_symbol = {}

      # one is internal trivial prefix
      @prefix = {:one => {:symbol => 'one', :value => 1} }
      @prefix_symbol = {'one' => :one}
      @prefix_value = {1 => :one}

      block.call(self) if block
    end

    def load(filename)
      data = YAML.load_file(File.join(File.dirname(__FILE__), 'systems', "#{filename}.yml"))

      (data['prefixes'] || {}).each do |name, prefix|
        name = name.to_sym
        symbols = [prefix['sym'] || []].flatten
        base = prefix['base']
        exp = prefix['exp']
        value = base ** exp
        $stderr.puts "Prefix #{name} already defined" if @prefix[name]
        @prefix[name] = { :symbol => symbols.first, :value => value }
        symbols.each do |sym|
          $stderr.puts "Prefix symbol #{sym} for #{name} already defined" if @prefix_symbol[name]
          @prefix_symbol[sym] = name
        end
        @prefix_symbol[name.to_s] = @prefix_value[value] = name
      end

      (data['units'] || {}).each do |name, unit|
        name = name.to_sym
        symbols = [unit['sym'] || []].flatten
        $stderr.puts "Unit #{name} already defined" if @unit[name]
        @unit[name] = { :symbol => symbols.first, :def => parse_unit(unit['def'])  }
        symbols.each do |sym|
          $stderr.puts "Unit symbol #{sym} for #{name} already defined" if @unit_symbol[name]
          @unit_symbol[sym] = name
        end
        @unit_symbol[name.to_s] = name
      end

      @unit.each {|name, unit| validate_unit(unit[:def]) }

      true
    end

    def validate_unit(units)
      units.each do |prefix, unit, exp|
        #raise TypeError, 'Prefix must be symbol' if !(Symbol === prefix)
        #raise TypeError, 'Unit must be symbol' if !(Numeric === unit || Symbol === unit)
        #raise TypeError, 'Exponent must be numeric' if !(Numeric === exp)
        raise TypeError, "Undefined prefix #{prefix}" if !@prefix[prefix]
        raise TypeError, "Undefined unit #{unit}" if !(Numeric === unit || @unit[unit])
      end
    end

    def parse_unit(expr)
      stack, result, implicit_mul = [], [], false
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
          stack << '*' if implicit_mul
          implicit_mul = true
          result << val
        end
      end
      compute(result, stack.pop) while !stack.empty?
      result.last
    end

    private

    REAL   = /^-?(?:(?:\d*\.\d+|\d+\.\d*)(?:[eE][-+]?\d+)?|\d+[eE][-+]?\d+)$/
    DEC    = /^-?\d+$/
    SYMBOL = /^[a-zA-Z_°'"][\w_°'"]*$/
    OPERATOR = { '/' => ['/', 1], '*' => ['*', 1], '·' => ['*', 1], '^' => ['^', 2], '**' => ['^', 2] }
    OPERATOR_TOKENS = OPERATOR.keys.sort_by {|x| -x.size }. map {|x| Regexp.quote(x) }
    VALUE_TOKENS = [REAL.source[1..-2], DEC.source[1..-2], SYMBOL.source[1..-2]]
    TOKENIZER = Regexp.new((OPERATOR_TOKENS + VALUE_TOKENS + ['\\(', '\\)']).join('|'))

    def lookup_symbol(symbol)
      if unit_symbol[symbol]
        [[:one, unit_symbol[symbol], 1]]
      else
        found = prefix_symbol.keys.find do |sym|
          symbol[0..sym.size-1] == sym && unit_symbol[symbol[sym.size..-1]]
        end
        [[prefix_symbol[found], unit_symbol[symbol[found.size..-1]], 1]] if found
      end
    end

    def symbol_to_unit(symbol)
      lookup_symbol(symbol) ||
        (symbol[-1..-1] == 's' ? lookup_symbol(symbol[0..-2]) : nil) || # Try english plural
        [[:one, symbol.to_sym, 1]]
    end

    def compute(result, op)
      b = result.pop
      a = result.pop
      result << case op
                when '*' then a + b
                when '/' then a + Unit.power_unit(b, -1)
                when '^' then Unit.power_unit(a, b[0][1])
                else raise SyntaxError, "Unexpected token #{op}"
                end
    end

    public

    SI = new('SI') do |system|
      system.load(:si)
      system.load(:binary)
      system.load(:degree)
      system.load(:time)
    end
  end

  class<< self
    attr_accessor :default_system
  end

  self.default_system = System::SI
end

def Unit(*args)
  numerator = Numeric === args.first ? args.shift : 1
  denominator = Numeric === args.first ? args.shift : 1

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

  Unit.new(numerator, denominator, unit, system)
end

class Numeric
  def to_unit(system = nil)
    system ||= Unit.default_system
    Unit.new(self, 1, [], system)
  end

  def method_missing(name, *args)
    Unit.method_name_to_unit(name).to_unit(*args) * self
  rescue TypeError => ex
    super
  end

  def unit(unit, system = nil)
    unit.to_unit(system) * self
  end
end

class Rational
  def to_unit(system = nil)
    system ||= Unit.default_system
    Unit.new(numerator, denominator, [], system)
  end
end

class String
  def to_unit(system = nil)
    system ||= Unit.default_system
    unit = system.parse_unit(self)
    system.validate_unit(unit)
    Unit.new(1, 1, unit, system)
  end
end

class Symbol
  def to_unit(system = nil)
    to_s.to_unit(system)
  end
end

class Array
  def to_unit(system = nil)
    system ||= Unit.default_system
    system.validate_unit(self)
    Unit.new(1, 1, self, system)
  end
end

# Units use symbols which must be sortable (Fix for Ruby 1.8)
if !:test.respond_to? :<=>
  class Symbol
    include Comparable
    def <=>(other)
      self.to_i <=> other.to_i
    end
  end
end
