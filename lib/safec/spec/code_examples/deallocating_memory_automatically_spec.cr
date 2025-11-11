require "../spec_helper"

module Safec::CodeSamples::DeallocatingMemoryAutomatically
  module SafePointer
    extend Safec::Macros

    safe_c_pointer Pointer(Void)

    class Free
      def free(p)
        LibC.free p
      end
    end
  end

  it name do
    p = LibC.malloc(4747)
    safe = SafePointer.free(p)
    safe.p.should eq p
  end
end
