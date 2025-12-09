### zig-epoch

simple lib to provide date time stamp with millisecond precision

output format provided by lib `yyyy.mm.dd HH:mi:ss.sss`

**usage**

```zig
const zigtime = @import('zig-epoch');
const std = @import('std');
const print = std.print.debug;
const threaded = std.Io.Threaded;


var arena_allocator = heap.ArenaAllocator.init(std.heap.page_allocator);


fn main() !void{
    var buf: [124]u8 = undefined;
    defer arena_allocator.deinit();
    var io_threaded = threaded.init(arena_allocator.allocator());
    defer io_threaded.deinit();
    const now = zigtime.Time.init(io_threaded.io(), &buf) catch |e| {
        std.debug.panic("error creating time:{any}\n", .{e});
    };
    print("now:{s}\n",.{now.fmt()});
    

}

```


### to contribute

- this repo follows commitlint
- create your branch, implement your changes 
- run test by using `zig test src/root.zig`
- raise a PR
