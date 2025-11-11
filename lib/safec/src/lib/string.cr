module Safec
  # Creates a new String instance with the *p* pointer.
  #
  # Returns nil if the *p* pointer is null.
  macro p_to_s?(p)
    %p = {{p}}
    %p.as(::Pointer(::Void)) == ::Pointer(::Void).null ? nil : ::String.new(%p.as(::Pointer(::UInt8)))
  end
end
