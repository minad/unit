# -*- coding: utf-8 -*-
require 'spec_helper'

describe Unit::System do
  let(:system) { Unit::System.new("test") }

  describe "#load" do
    it "should load an IO object" do
      system.load(:si)
      test_file = File.join(File.dirname(__FILE__), "yml", "io.yml")
      File.open(test_file) { |file| system.load(file) }
      expect(Unit(1, "pim", system)).to eq(Unit(3.14159, "m", system))
    end

    context "when passed a String" do
      context "that is a filename" do
        it "should load the file" do
          filename = File.join(File.dirname(__FILE__), "yml", "filename.yml")
          system.load(:si)
          system.load(filename)
          expect(Unit(2, "dzm", system)).to eq(Unit(24, "m", system))
        end
      end

      context "that is not a filename" do
        it "should load the built-in system of that name" do
          system.load("si")
          expect { Unit(2, 'm', system) }.not_to raise_exception
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
          expect(Unit(2, "dzm", system)).to eq(Unit(24, "m", system))
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
          expect(Unit(2, "dzm", system)).to eq(Unit(24, "m", system))
        end
      end

      context "when passed an invalid factor" do
        it "should raise an exception" do
          system.load(:si)
          expect {
            system.load(
              'factors' => {
                'dozen' => {
                  'sym' => 'dz'
                }
              }
            )
          }.to raise_exception("Invalid definition for factor dozen")
        end
      end
    end

    context "when called on the same filename a second time" do
      it "should be a no-op" do
        expect($stderr).not_to receive(:puts)
        test_file = File.join(File.dirname(__FILE__), "yml", "filename.yml")
        system.load(:si)
        system.load(test_file)
        expect { system.load(test_file) }.not_to raise_exception
      end
    end

    context "when called on the same symbol a second time" do
      it "should be a no-op" do
        expect($stderr).not_to receive(:puts)
        system.load(:si)
        expect { system.load(:si) }.not_to raise_exception
      end
    end
  end
end
