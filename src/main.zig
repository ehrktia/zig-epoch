const std = @import("std");
const print = std.debug.print;
const epoch = std.time.epoch;
const day_seconds = epoch.DaySeconds;
const io = std.Io;
const heap = std.heap;
const threaded = io.Threaded;
const clock = io.Clock;
const epoch_seconds = epoch.EpochSeconds;
const day_epoch_seconds = epoch.DaySeconds;
const epoch_day = epoch.EpochDay;
const epoch_year_day = epoch.YearAndDay;

const real_clock = clock.real;
var arena_allocator = heap.ArenaAllocator.init(std.heap.page_allocator);
pub fn main() !void {
    defer arena_allocator.deinit();
    var io_threaded = threaded.init(arena_allocator.allocator());
    defer io_threaded.deinit();
    var buffer: [124]u8 = undefined;
    const t = try Time.init(io_threaded.io(), &buffer);
    const data = try t.fmt();
    print("{s}\n", .{data});
}

const Time = struct {
    const Self = @This();
    hrs: u5,
    min: u6,
    sec: u6,
    month: u4,
    day: u5,
    year: u16,
    buffer: []u8,
    pub fn init(std_io: io, buffer: []u8) !Time {
        const timestamp = try clock.now(real_clock, std_io);
        const sec = io.Timestamp.toSeconds(timestamp);
        const sec_unsigned: u64 = @as(u64, @intCast(sec));
        const day_sec = epoch_seconds.getDaySeconds(epoch_seconds{ .secs = sec_unsigned });
        const hrs = day_epoch_seconds.getHoursIntoDay(day_sec);
        const mins = day_epoch_seconds.getMinutesIntoHour(day_sec);
        const secs = day_epoch_seconds.getSecondsIntoMinute(day_sec);
        const day = epoch_seconds.getEpochDay(epoch_seconds{ .secs = sec_unsigned });
        const yr_day = epoch_day.calculateYearDay(day);
        const mon_day = epoch_year_day.calculateMonthDay(yr_day);
        return Time{
            .hrs = hrs,
            .min = mins,
            .sec = secs,
            .month = mon_day.month.numeric(),
            .day = mon_day.day_index + 1,
            .year = yr_day.year,
            .buffer = buffer,
        };
    }
    pub fn fmt(self: Self) ![]u8 {
        const fs_std_out = std.fs.File.stdout();
        var fs_writer = fs_std_out.writer(self.buffer);
        const writer = &fs_writer.interface;
        defer writer.flush() catch unreachable;
        return std.fmt.bufPrint(self.buffer, "{d}-{d}-{d} {d}:{d}:{d}", .{ self.year, self.month, self.day, self.hrs, self.min, self.sec }) catch |e| {
            return e;
        };
    }
};
