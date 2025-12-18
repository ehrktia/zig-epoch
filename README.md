### zig-epoch
![clock](docs/clock.jpg "clock")   

simple lib to provide date time stamp with millisecond precision 
No linked or dependent C libs 

output format provided by lib `yyyy.mm.dd HH:mi:ss.sss`

**usage**

```zig
const std = @import("std");
const zig_epoch = @import("zig_epoch");
const clock = zig_epoch.Time
pub fn main() !void {
    var arena_allocator = heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    var io_threaded = threaded.init(arena_allocator.allocator());
    defer io_threaded.deinit();
    var threaded_io = io_threaded.io();
    const tnow = Time.create(&threaded_io);
    std.log.info("{s}: welcome", .{tnow.now()});
}



```

`output: info: 2025-12-14 10:24:02.236: welcome`


### to contribute

- this repo follows commitlint
- create your branch, implement your changes 
- run test by using `zig test src/root.zig`
- raise a PR
