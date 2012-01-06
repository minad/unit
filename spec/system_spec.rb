# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Unit" do
  describe "#default_system" do
    describe "#load" do
      it "should load an IO object" do
        test_file = File.join(File.dirname(__FILE__), "yml", "io.yml")
        File.open(test_file) do |file|
          Unit.default_system.load(file)
        end
        Unit(1, "pim").should == Unit(3.14159, "m")
      end

      it "should load a file" do
        test_file = File.join(File.dirname(__FILE__), "yml", "filename.yml")
        Unit.default_system.load(test_file)
        Unit(2, "dzm").should == Unit(24, "m")
      end

      it "should load a hash" do
        Unit.default_system.load({
          'dozen_meter' => {
            'sym' => 'dzm',
            'def' => '12 m'
          }
        })
        Unit(2, "dzm").should == Unit(24, "m")
      end
    end
  end
end
