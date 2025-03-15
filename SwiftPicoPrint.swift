@_extern(c, "putchar")
func putchar(_: Int32) -> Int32

func sputchar(_ c: UInt8) {
  putchar(Int32(c))
}

@inline(__always)
public func print(_ s: StaticString, terminator: StaticString = "\n") {
  var p = s.utf8Start
  while p.pointee != 0 {
    sputchar(p.pointee)
    p += 1
  }
  p = terminator.utf8Start
  while p.pointee != 0 {
    sputchar(p.pointee)
    p += 1
  }
}
