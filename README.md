### zig-epoch
![clock](docs/clock.jpg "clock")   



Thank you to the good people from zig discord showcase channel did review and helped me with the code    

simple lib to provide date time stamp with millisecond precision 
No linked or dependent C libs 

output format provided by lib:
- now() function: `yyyy.mm.dd HH:mi:ss.sss`
- nowSyslog() function: `Mon dd HH:mi:ss`

**usage**

```zig
const std = @import("std");
const zig_epoch = @import("zig_epoch");
const clock = zig_epoch.Time
pub fn main() !void {
var heap_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer heap_allocator.deinit();
    var threaded = std.Io.Threaded.init(heap_allocator.allocator());
    defer threaded.deinit();
    var threaded_io = threaded.io();
    const now_time = epch.Time.create(&threaded_io);
    std.log.info("{s}\n", .{now_time.now()});
    std.log.info("{s}\n", .{now_time.nowSyslog()});

}

```

`output: info: 2025-12-14 10:24:02.236`
`output: info: Dec 14 10:24:02`


### to contribute

- this repo follows commitlint
- create your branch, implement your changes 
- run test by using `zig test src/root.zig`
- raise a PR   
