require "./spec_helper"

describe Rat::Highlighter do
  describe ".highlight" do
    it "returns the original line for plain text" do
      line = "This is a plain text line.\n"
      path = "test.txt"
      first_line = line

      highlighted = Rat::Highlighter.highlight(line, path, first_line)
      highlighted.should eq line
    end

    it "returns the original line if the path is unknown" do
      line = "def foo; end"
      path = "unknown.file_extension"
      first_line = line

      highlighted = Rat::Highlighter.highlight(line, path, first_line)
      highlighted.should eq line
    end

    # Add a tests for all known languages. 
    # probably just gonna use crystal 
    # or bash/shell script for this later
    # maybe ruby if i actually care enough 
    # to test syntax highlighting for that
    # language
    pending "TODO: Add test for a specific language (e.g., ruby)"
    # it "highlights ruby code" do
    #   line = "def foo; end\n"
    #   path = "test.rb"
    #   first_line = line
    #
    #   highlighted = Rat::Highlighter.highlight(line, path, first_line)
    #   highlighted.should_not eq line
    #   highlighted.should contain "\e[" # ANSI escape code
    # end
  end
end
