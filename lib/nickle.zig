//! Nickle is a compiler framework similar to LLVM.
//! It has its own IR and bytecode format.

pub const arch = @import("nickle/arch.zig");
pub const codegen = @import("nickle/codegen.zig");
pub const ir = @import("nickle/ir.zig");
pub const ofmt = @import("nickle/ofmt.zig");
pub const Type = @import("nickle/Type.zig");

test {
    _ = arch;
    _ = codegen;
    _ = ir;
    _ = ofmt;
    _ = Type;
}
