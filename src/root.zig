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

fn check_day(day: u5) ![2]u8 {
    var b: [2]u8 = undefined;
    if (day > 9) {
        _ = try std.fmt.bufPrint(&b, "{d}", .{day});
        return b;
    }
    _ = try std.fmt.bufPrint(&b, "0{d}", .{day});
    return b;
}

pub fn now() [24]u8 {
    var threaded_io = threaded.init(arena_allocator.allocator());
    defer arena_allocator.deinit();
    defer threaded_io.deinit();
    var buffer: [24]u8 = undefined;
    const timestamp = clock.now(real_clock, threaded_io.ioBasic()) catch unreachable;
    const sec = io.Timestamp.toSeconds(timestamp);
    const sec_unsigned: u64 = @as(u64, @intCast(sec));
    const day_sec = epoch_seconds.getDaySeconds(epoch_seconds{ .secs = sec_unsigned });
    const hrs = day_epoch_seconds.getHoursIntoDay(day_sec);
    const mins = day_epoch_seconds.getMinutesIntoHour(day_sec);
    const secs = day_epoch_seconds.getSecondsIntoMinute(day_sec);
    const day = epoch_seconds.getEpochDay(epoch_seconds{ .secs = sec_unsigned });
    const yr_day = epoch_day.calculateYearDay(day);
    const mon_day = epoch_year_day.calculateMonthDay(yr_day);
    const day_check = check_day(mon_day.day_index + 1) catch unreachable;
    const mill = io.Timestamp.toMilliseconds(timestamp);
    _ = std.fmt.bufPrint(&buffer, "{d}-{d}-{s} {d}:{d}:{d}.{d}", .{ yr_day.year, mon_day.month.numeric(), day_check, hrs, mins, secs, @rem(mill, 1000) }) catch unreachable;
    return buffer;
}
const Time = struct {
    const Self = @This();
    hrs: u5,
    min: u6,
    sec: u6,
    month: u4,
    day: [2]u8,
    year: u16,
    buffer: []u8,
    timestamp: io.Timestamp,
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
        const day_check = try check_day(mon_day.day_index + 1);
        return Time{
            .hrs = hrs,
            .min = mins,
            .sec = secs,
            .month = mon_day.month.numeric(),
            .day = day_check,
            .year = yr_day.year,
            .buffer = buffer,
            .timestamp = timestamp,
        };
    }
    pub fn fmt(self: Self) ![]u8 {
        const fs_std_out = std.fs.File.stdout();
        var fs_writer = fs_std_out.writer(self.buffer);
        const writer = &fs_writer.interface;
        defer writer.flush() catch unreachable;
        const mill = io.Timestamp.toMilliseconds(self.timestamp);
        return std.fmt.bufPrint(self.buffer, "{d}-{d}-{s} {d}:{d}:{d}.{d}", .{ self.year, self.month, self.day, self.hrs, self.min, self.sec, @rem(mill, 1000) }) catch |e| {
            return e;
        };
    }
};

// ===========================================================
// ====================unit test==============================
// ===========================================================

test "create time" {
    var buf: [124]u8 = undefined;
    defer arena_allocator.deinit();
    var io_threaded = threaded.init(arena_allocator.allocator());
    defer io_threaded.deinit();
    const tnow = Time.init(io_threaded.io(), &buf) catch |e| {
        std.debug.panic("error creating time:{any}\n", .{e});
    };
    const tot_len = try tnow.fmt();
    try std.testing.expect(tot_len.len > 0);
}

test "day_with_prefix" {
    const d: u5 = 5;
    const day = try check_day(d);
    try std.testing.expect(day[0] != 0);
}

test "day_with_no_prefix" {
    const d: u5 = 15;
    const day = try check_day(d);
    try std.testing.expect(day[0] != 1);
}

test "now" {
    const time_now = now();
    print("now:{s}\n", .{time_now});
}
