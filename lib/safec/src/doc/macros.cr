module Safec
  module Macros
    # Usage example for the `safe_c_pointer` macro.
    module SafeCPointerMacroExample
      extend Safec::Macros

      safe_c_pointer Pointer(Void)

      class Free
        def free(p)
          LibC.free p
        end
      end
    end

    # Usage example for the `safe_c_struct` macro.
    module SafeCStructMacroExample
      extend Safec::Macros

      lib C
        struct Struct
        end
      end

      safe_c_struct C::Struct

      class Free
        def free(p)
          LibC.free p
        end
      end
    end
  end
end
