require "../spec_helper.cr"
require "spec"

describe Highlighter do
  it "detects language from extension" do
    Highlighter.detect_language("file.cr", "").should eq "crystal"
    Highlighter.detect_language("file.rs", "").should eq "rust"
    Highlighter.detect_language("file.py", "").should eq "python"
    Highlighter.detect_language("file.js", "").should eq "js"
  end

  it "detects language from shebang" do
    Highlighter.detect_language("", "#!/usr/bin/env python").should eq "python"
    Highlighter.detect_language("", "#!/usr/bin/env ruby").should eq "ruby"
    Highlighter.detect_language("", "#!/usr/bin/env node").should eq "node"
  end

  it "returns colored string for known language highlighting" do
    out = Highlighter.highlight("def hello\n", "test.cr", "")
    out.includes?(Highlighter::KEYWORD_COLOR).should be_true
  end

  it "leaves unknown file types mostly unchanged (but not nil)" do
    out = Highlighter.highlight("plain text\n", "README.txt", "")
    out.should be_a String
  end
end
