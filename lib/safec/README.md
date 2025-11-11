# Safec

A Crystal library for wrapping C values in its safe way.

[![Build Status](https://travis-ci.org/mosop/safec.svg?branch=master)](https://travis-ci.org/mosop/safec)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  git:
    github: mosop/safec
```

<a name="code_samples"></a>
## Code Samples

### Deallocating Memory Automatically

The `Free` class represents a C pointer to memory that is got free on GC finalize.

To deallocate memory, you must implement the `Free#free` method.

```crystal
module SafePointer
  extend Safec::Macros

  safe_c_pointer Pointer(Void)

  class Free
    def free(p)
      LibC.free p
    end
  end
end

p = LibC.malloc(4747)
safe = SafePointer.free(p)
safe.p == p # true
```

### Using "Unfree" Pointers

The `Unfree` class represents a C pointer to memory that is not automatically got free.

```crystal
module SafePointer
  extend Safec::Macros

  safe_c_pointer Pointer(LibC::Char), free: false
end

p = ":)".to_unsafe
safe = SafePointer.unfree(p)
safe.p == p # true
```

### Union of Pointers

You can access "free" and "unfree" pointers in polymorphic way.

```crystal
module Profile
  extend Safec::Macros

  safe_c_pointer Pointer(C::Profile)

  class Free
    def free(p)
      LibC.free p
    end
  end

  lib C
    struct Profile
      name : UInt8[255]
      homepage : UInt8[255]
    end
  end
end

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

profiles.each do |profile|
  puts String.new(profile.p.value.name.to_unsafe)
  puts String.new(profile.p.value.homepage.to_unsafe)
end
```

Output:

```
mosop
http://mosop.me
usop
http://usop.ninja
```

### Using Structs

```crystal
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

faces.each do |face|
  print face.value.eyes
  puts face.value.mouth
end
```

Output:

```
:)
;P
Xo
```

## Usage

```crystal
require "safec"
```

and see:

* [Code Samples](#code_samples)
* [API Document](http://mosop.me/safec/Safec.html)

## Release Notes

See [Releases](https://github.com/mosop/safec/releases).
