### zig-epoch

simple lib to provide date time stamp with millisecond precision

output format provided by lib `yyyy.mm.dd HH:mi:ss.sss`

**usage**

```zig
const std = @import("std");
const zig_epoch = @import("zig_epoch");
pub fn main() !void {
    std.debug.print("{s}\n", .{zig_epoch.now()});
}


```


### to contribute

- this repo follows commitlint
- create your branch, implement your changes 
- run test by using `zig test src/root.zig`
- raise a PR
