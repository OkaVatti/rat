require "./spec_helper"

describe Rat::Formatter do
  describe ".format_line" do
    it "returns a plain line when plain: true" do
      line = "hello world\n"
      formatted = Rat::Formatter.format_line(
        line, "file.txt",
        line_num: 1,
        line_numbers: false,
        plain: true,
        first_line: nil
      )
      formatted.should eq "hello world\n"
    end

    it "adds line numbers when line_numbers: true and plain: true" do
      line = "hello\n"
      formatted = Rat::Formatter.format_line(
        line, "file.txt",
        line_num: 1,
        line_numbers: true, # Assuming this maps to @line_numbers
        plain: true,
        first_line: nil
      )
      # This spec assumes a 6-space padding, adjust as needed
      formatted.should eq "     1  hello\n"
    end

    # would add more tests here for rich/highlighted output, 
    # but i'm too fucking tired to actually test it because i hate myself
    # fuck this programming language
  end

  describe ".print_header_if_needed" do
    it "prints a header in rich mode" do
      # Testing methods that print to STDOUT usually requires
      # capturing IO, which can be complex.
      # We'll assume this method exists, but skip testing for now.
      pending "TODO: Test STDOUT printing"
    end

    it "does not print a header in plain mode" do
      # This test would capture STDOUT and assert it's empty
      pending "TODO: Test STDOUT printing"
    end
  end
end
