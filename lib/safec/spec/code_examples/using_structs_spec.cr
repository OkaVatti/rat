require "../spec_helper"

module Safec::CodeSamples::UsingStructs
  module Face
    extend Safec::Macros

    lib C
      struct Face
        eyes : Char
        mouth : Char
      end
    end

    safe_c_struct C::Face

    class Free
      def free(p)
        LibC.free p
      end
    end
  end

  it name do
    faces = [] of Face::Type

    # Append a "value" face.
    value = Face::C::Face.new
    value.eyes = ':'
    value.mouth = ')'
    faces << Face.value(value)

    # Append a "free" face.
    p = LibC.malloc(sizeof(Face::C::Face)).as(Face::C::Face*)
    p.value.eyes = ';'
    p.value.mouth = 'P'
    faces << Face.free(p)

    # Append an "unfree" face.
    value = Face::C::Face.new
    value.eyes = 'X'
    value.mouth = 'o'
    faces << Face.unfree(pointerof(value))

    Stdio.capture do |io|
      faces.each do |face|
        print face.value.eyes
        puts face.value.mouth
      end
      io.out.gets_to_end.chomp.should eq <<-EOS
      :)
      ;P
      Xo
      EOS
    end
  end
end
