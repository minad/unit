# -*- coding: utf-8 -*-
require 'spec_helper'

describe Unit::System do
  let(:system) { Unit::System.new("test") }

  describe "#load" do
    it "should load an IO object" do
      system.load(:si)
      test_file = File.join(File.dirname(__FILE__), "yml", "io.yml")
      File.open(test_file) { |file| system.load(file) }
      Unit(1, "pim", system).should == Unit(3.14159, "m", system)
    end

    context "when passed a String" do
      context "that is a filename" do
        it "should load the file" do
          filename = File.join(File.dirname(__FILE__), "yml", "filename.yml")
          system.load(:si)
          system.load(filename)
          Unit(2, "dzm", system).should == Unit(24, "m", system)
        end
      end

      context "that is not a filename" do
        it "should load the built-in system of that name" do
          system.load("si")
          lambda { Unit(2, 'm', system) }.should_not raise_exception
        end
      end
    end

    context "when passed a Hash" do
      context "of units" do
        it "should load the units" do
          system.load(:si)
          system.load(
            'units' => {
              'dozen_meter' => {
                'sym' => 'dzm',
                'def' => '12 m'
              }
            }
          )
          Unit(2, "dzm", system).should == Unit(24, "m", system)
        end
      end

      context "of factors" do
        it "should load the factors" do
          system.load(:si)
          system.load(
            'factors' => {
              'dozen' => {
                'sym' => 'dz',
                'def' => 12
              }
            }
          )
          Unit(2, "dzm", system).should == Unit(24, "m", system)
        end
      end

      context "when passed an invalid factor" do
        it "should raise an exception" do
          system.load(:si)
          lambda {
            system.load(
              'factors' => {
                'dozen' => {
                  'sym' => 'dz'
                }
              }
            )
          }.should raise_exception("Invalid definition for factor dozen")
        end
      end
    end
  end
end
