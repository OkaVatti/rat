require "../spec_helper"

module Safec::CodeSamples::UnionOfPointers
  module Profile
    extend Safec::Macros

    lib C
      struct Profile
        name : UInt8[255]
        homepage : UInt8[255]
      end
    end

    safe_c_pointer Pointer(C::Profile)

    class Free
      def free(p)
        LibC.free p
      end
    end
  end

  it name do
    profiles = [] of Profile::Type

    # Append a "free" profile.
    p = LibC.malloc(sizeof(Profile::C::Profile)).as(Profile::C::Profile*)
    name = "mosop".bytes
    homepage = "http://mosop.me".bytes
    p.value.name = StaticArray(UInt8, 255).new{|i| name[i]? || 0_u8}
    p.value.homepage = StaticArray(UInt8, 255).new{|i| homepage[i]? || 0_u8}
    profiles << Profile.free(p)

    # Append an "unfree" profile.
    value = Profile::C::Profile.new
    name = "usop".bytes
    homepage = "http://usop.ninja".bytes
    value.name = StaticArray(UInt8, 255).new{|i| name[i]? || 0_u8}
    value.homepage = StaticArray(UInt8, 255).new{|i| homepage[i]? || 0_u8}
    profiles << Profile.unfree(pointerof(value))

    Stdio.capture do |io|
      profiles.each do |profile|
        puts String.new(profile.p.value.name.to_unsafe)
        puts String.new(profile.p.value.homepage.to_unsafe)
      end
      io.out.gets_to_end.chomp.should eq <<-EOS
      mosop
      http://mosop.me
      usop
      http://usop.ninja
      EOS
    end
  end
end
