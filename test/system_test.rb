# -*- coding: utf-8 -*-
require 'bacon'
require 'unit'
require 'unit/dsl'

describe "Unit" do
  describe "#default_system" do
    describe "#load" do
      it "should load an IO object" do
        test_file = File.join(File.dirname(__FILE__), "yml", "io.yml")
        File.open(test_file) do |file|
          Unit.default_system.load(file)
        end
        Unit(1, "pim").should.equal Unit(3.14159, "m")
      end

      it "should load a file" do
        test_file = File.join(File.dirname(__FILE__), "yml", "filename.yml")
        Unit.default_system.load(test_file)
        Unit(2, "dzm").should.equal Unit(24, "m")
      end
    end
  end
end
