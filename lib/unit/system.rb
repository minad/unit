# -*- coding: utf-8 -*-
require 'yaml'

class Unit < Numeric
  class System
    attr_reader :name, :unit, :unit_symbol, :factor, :factor_symbol, :factor_value

    def initialize(name)
      @name = name
      @unit = {}
      @unit_symbol = {}

      # one is internal trivial factor
      @factor = {:one => {:symbol => 'one', :value => 1} }
      @factor_symbol = {'one' => :one}
      @factor_value = {1 => :one}

      @loaded_systems = []
      @loaded_filenames = []

      yield(self) if block_given?
    end

    def load(input)
      case input
      when Hash
        data = input
      when IO
        data = YAML.load(input.read)
      when String
        if File.exist?(input)
          return if @loaded_filenames.include?(input)
          data = YAML.load_file(input)
          @loaded_filenames << input
        else
          load(input.to_sym)
          return
        end
      when Symbol
        return if @loaded_systems.include?(input)
        data = YAML.load_file(File.join(File.dirname(__FILE__), 'systems', "#{input}.yml"))
        @loaded_systems << input
      end

      load_factors(data['factors']) if data['factors']
      load_units(data['units']) if data['units']

      @unit.each {|name, unit| validate_unit(unit[:def]) }

      true
    end

    def validate_unit(units)
      units.each do |factor, unit, exp|
        #raise TypeError, 'Factor must be symbol' if !(Symbol === factor)
        #raise TypeError, 'Unit must be symbol' if !(Numeric === unit || Symbol === unit)
        #raise TypeError, 'Exponent must be numeric' if !(Numeric === exp)
        raise TypeError, "Undefined factor #{factor}" if !@factor[factor]
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
    SYMBOL = /^[a-zA-Z_°'"][\w°'"]*$/
    OPERATOR = { '/' => ['/', 1], '*' => ['*', 1], '·' => ['*', 1], '^' => ['^', 2], '**' => ['^', 2] }
    OPERATOR_TOKENS = OPERATOR.keys.sort_by {|x| -x.size }. map {|x| Regexp.quote(x) }
    VALUE_TOKENS = [REAL.source[1..-2], DEC.source[1..-2], SYMBOL.source[1..-2]]
    TOKENIZER = Regexp.new((OPERATOR_TOKENS + VALUE_TOKENS + ['\\(', '\\)']).join('|'))

    def lookup_symbol(symbol)
      if unit_symbol[symbol]
        [[:one, unit_symbol[symbol], 1]]
      else
        found = factor_symbol.keys.find do |sym|
          symbol[0..sym.size-1] == sym && unit_symbol[symbol[sym.size..-1]]
        end
        [[factor_symbol[found], unit_symbol[symbol[found.size..-1]], 1]] if found
      end
    end

    def symbol_to_unit(symbol)
      lookup_symbol(symbol) ||
        (symbol[-1..-1] == 's' ? lookup_symbol(symbol[0..-2]) : nil) || # Try english plural
        [[:one, symbol.to_sym, 1]]
    end

    def compute(result, op)
      b = result.pop
      a = result.pop || raise(SyntaxError, "Unexpected token #{op}")
      result << case op
                when '*' then a + b
                when '/' then a + Unit.power_unit(b, -1)
                when '^' then Unit.power_unit(a, b[0][1])
                else raise SyntaxError, "Unexpected token #{op}"
                end
    end

    def load_factors(factors)
      factors.each do |name, factor|
        name = name.to_sym
        symbols = [factor['sym'] || []].flatten
        base, exp = factor["def"].to_s.split("^").map { |value| Integer(value) }
        exp ||= 1
        raise "Invalid definition for factor #{name}" unless base
        value = base ** exp
        $stderr.puts "Factor #{name} already defined" if @factor[name]
        @factor[name] = { :symbol => symbols.first, :value => value }
        symbols.each do |sym|
          $stderr.puts "Factor symbol #{sym} for #{name} already defined" if @factor_symbol[name]
          @factor_symbol[sym] = name
        end
        @factor_symbol[name.to_s] = @factor_value[value] = name
      end
    end

    def load_units(units)
      units.each do |name, unit|
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
    end

    SI = new('SI') do |system|
      system.load(:si)
      system.load(:binary)
      system.load(:degree)
      system.load(:time)
    end

    Unit.default_system = SI
  end
end
