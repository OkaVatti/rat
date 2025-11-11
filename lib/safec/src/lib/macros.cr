module Safec
  # Extends modules with the helper macros.
  #
  # See:
  # * `SafeCPointerMacroExample`
  # * `SafeCStructMacroExample`
  module Macros
    macro extended
      # Defines the classes for wrapping C pointers.
      #
      # Defines the `Free` and `Unfree` classes for wrapping C pointers.
      #
      # To define the `Free` class, you must implement the `AsFree#free` method to deallocate memory.
      #
      # To define the `Unfree` class only, set *free* falsey.
      #
      # This macro was automatically defined by the Safec library.
      macro safe_c_pointer(klass, free = true)
        \{%
          klass = klass.resolve if klass.class_name == "Path"
        \%}

        \{% if free %}
        # A union of the wrapper class types to specify the types as polymorphic.
        #
        # This alias was automatically defined by the Safec library.
        alias Type = Free | Unfree
        \{% end %}

        @@null : Unfree = unfree(::Pointer(::Void).null.as(\{{klass}}))
        # Returns an `Unfree` instance initialized with a null pointer.
        def self.null
          @@null
        end

        \{% if free %}
        # Defines the abstract methods for the `Free` class.
        #
        # This module was automatically defined by the Safec library.
        module AsFree
          # Deallocates the memory pointed by the *p* pointer.
          abstract def free(p : \{{klass}})
        end

        # Represents a C pointer to memory that is got free on GC finalize.
        #
        # This class was automatically defined by the Safec library.
        class Free
          include AsFree

          @p : \{{klass}}

          # :nodoc:
          def initialize(@p)
          end

          # :nodoc:
          def finalize
            free @p
          end

          # Tests if this pointer is null.
          def null?
            @p.as(::Void*) == ::Pointer(::Void).null
          end

          # Returns this C pointer.
          def p
            @p
          end

          # Returns this C pointer.
          def to_unsafe
            @p
          end
        end

        # Creates a new `Free` instance initialized with the *p* pointer.
        #
        # This class was automatically defined by the Safec library.
        def self.free(p : \{{klass}})
          Free.new(p)
        end
        \{% end %}

        # Represents a C pointer to memory that is not automatically got free.
        #
        # This class was automatically defined by the Safec library.
        class Unfree
          @p : \{{klass}}

          # :nodoc:
          def initialize(@p)
          end

          # Tests if this pointer is null.
          def null?
            @p.as(::Void*) == ::Pointer(::Void).null
          end

          # Returns this C pointer.
          def p
            @p
          end

          # Returns this C pointer.
          def to_unsafe
            @p
          end
        end

        # Creates a new `Unfree` instance initialized with the *p* pointer.
        #
        # This class was automatically defined by the Safec library.
        def self.unfree(p : \{{klass}})
          Unfree.new(p)
        end
      end

      # Defines the classes for wrapping C structs.
      #
      # Defines the `Value`, `Free` and `Unfree` classes for wrapping C structs.
      #
      # To define the `Free` class, you must implement the `AsFree#free` method to deallocate memory.
      #
      # To define the `Value` and `Unfree` classes only, set *free* falsey.
      #
      # This macro was automatically defined by the Safec library.
      macro safe_c_struct(klass, free = true)
        \{%
          klass = klass.resolve if klass.class_name == "Path"
        \%}

        \{% if free %}
          # A union of the wrapper class types to specify the types as polymorphic.
          #
          # This alias was automatically defined by the Safec library.
          alias Type = Value | Free | Unfree
        \{% else %}
        # A union of the wrapper class types to specify the types as polymorphic.
        #
        # This alias was automatically defined by the Safec library.
          alias Type = Value | Unfree
        \{% end %}

        @@null : Unfree = unfree(::Pointer(::Void).null.as(\{{klass}}*))
        # Returns an `Unfree` instance initialized with a null pointer.
        def self.null
          @@null
        end

        class Value
          @value : \{{klass}}

          def initialize(@value)
          end

          # Returns a pointer to this value.
          def p
            pointerof(@value)
          end

          # Returns this value.
          def value
            @value
          end

          # Returns this value.
          def to_unsafe
            @value
          end

          # Duplicates this value.
          def dup
            Value.new(@value)
          end
        end

        # Creates a new `Value` instance initialized with the *value* value.
        #
        # This class was automatically defined by the Safec library.
        def self.value(value)
          Value.new(value)
        end

        \{% if free %}
        # Defines the abstract methods for the `Free` class.
        #
        # This module was automatically defined by the Safec library.
        module AsFree
          # Deallocates the memory pointed by the *p* pointer.
          abstract def free(p : \{{klass}}*)
        end

        # Represents a C pointer to memory that is got free on GC finalize.
        #
        # This class was automatically defined by the Safec library.
        class Free
          include AsFree

          @p : \{{klass}}*

          # :nodoc:
          def initialize(@p)
          end

          # :nodoc:
          def finalize
            free @p
          end

          # Tests if this pointer is null.
          def null?
            @p.as(::Void*) == ::Pointer(::Void).null
          end

          # Returns this C pointer.
          def p
            @p
          end

          # Returns this C pointer.
          def to_unsafe
            @p
          end

          # Return the struct value pointed by this pointer.
          def value
            @p.value
          end
        end

        # Creates a new `Free` instance initialized with the *p* pointer.
        #
        # This class was automatically defined by the Safec library.
        def self.free(p : \{{klass}}*)
          Free.new(p)
        end
        \{% end %}

        # Represents a C pointer to memory that is got free on GC finalize.
        #
        # This class was automatically defined by the Safec library.
        class Unfree
          @p : \{{klass}}*

          # :nodoc:
          def initialize(@p)
          end

          # Tests if this pointer is null.
          def null?
            @p.as(::Void*) == ::Pointer(::Void).null
          end

          # Returns this C pointer.
          def p
            @p
          end

          # Returns this C pointer.
          def to_unsafe
            @p
          end

          # Return the struct value pointed by this pointer.
          def value
            @p.value
          end
        end

        # Creates a new `Unfree` instance initialized with the *p* pointer.
        #
        # This class was automatically defined by the Safec library.
        def self.unfree(p : \{{klass}}*)
          Unfree.new(p)
        end
      end
    end
  end
end
