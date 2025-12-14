### zig-epoch

simple lib to provide date time stamp with millisecond precision

output format provided by lib `yyyy.mm.dd HH:mi:ss.sss`

**usage**

```zig
const std = @import("std");
const zig_epoch = @import("zig_epoch");
pub fn main() !void {
    std.log.info("{s}: welcome", .{zig_epoch.now()});
}



```

`output: info: 2025-12-14 10:24:02.236: welcome`


### to contribute

- this repo follows commitlint
- create your branch, implement your changes 
- run test by using `zig test src/root.zig`
- raise a PR
