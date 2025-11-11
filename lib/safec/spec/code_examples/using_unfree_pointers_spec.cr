require "../spec_helper"

module Safec::CodeSamples::UsingUnfreePointers
  module SafePointer
    extend Safec::Macros

    safe_c_pointer Pointer(LibC::Char), free: false
  end

  it name do
    p = ":)".to_unsafe
    safe = SafePointer.unfree(p)
    safe.p.should eq p
  end
end
