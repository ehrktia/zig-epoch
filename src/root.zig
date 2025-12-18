const std = @import("std");
const print = std.debug.print;
const epoch = std.time.epoch;
const day_seconds = epoch.DaySeconds;
const std_io = std.Io;
const heap = std.heap;
const threaded = std_io.Threaded;
const clock = std_io.Clock;
const epoch_seconds = epoch.EpochSeconds;
const day_epoch_seconds = epoch.DaySeconds;
const epoch_day = epoch.EpochDay;
const epoch_year_day = epoch.YearAndDay;
const panic = std.debug.panic;

const real_clock = clock.real;
var arena_allocator = heap.ArenaAllocator.init(std.heap.page_allocator);

fn check_decimal(comptime T: type, in: T) ![2]u8 {
    var b: [2]u8 = undefined;
    if (in > 9) {
        _ = try std.fmt.bufPrint(&b, "{d}", .{in});
        return b;
    }
    _ = try std.fmt.bufPrint(&b, "0{d}", .{in});
    return b;
}

fn check_m_sec(in: i64) ![3]u8 {
    var b: [3]u8 = undefined;
    switch (in) {
        0...9 => {
            _ = try std.fmt.bufPrint(&b, "00{d}", .{in});
            return b;
        },
        10...99 => {
            _ = try std.fmt.bufPrint(&b, "0{d}", .{in});
            return b;
        },
        else => {
            _ = try std.fmt.bufPrint(&b, "{d}", .{in});
            return b;
        },
    }
}

const Time = struct {
    const Self = @This();
    io: *std.Io,
    pub fn create(io: *std.Io) Time {
        return Time{
            .io = io,
        };
    }
    pub fn now(self: Self) [23]u8 {
        var buf: [23]u8 = undefined;
        defer arena_allocator.deinit();
        const timestamp = clock.now(real_clock, self.io.*) catch |e| {
            panic("failed to get clock:{any}\n", .{e});
        };
        const sec = std.Io.Timestamp.toSeconds(timestamp);
        const sec_unsigned: u64 = @as(u64, @intCast(sec));
        const day_sec = epoch_seconds.getDaySeconds(epoch_seconds{ .secs = sec_unsigned });
        const hrs = day_epoch_seconds.getHoursIntoDay(day_sec);
        const hr = check_decimal(u5, hrs) catch |e| {
            panic("{any}\n", .{e});
        };
        const mins = day_epoch_seconds.getMinutesIntoHour(day_sec);
        const min = check_decimal(u6, mins) catch |e| {
            panic("{any}\n", .{e});
        };
        const secs = day_epoch_seconds.getSecondsIntoMinute(day_sec);
        const sec_padded = check_decimal(u6, secs) catch |e| {
            panic("{any}\n", .{e});
        };
        const day = epoch_seconds.getEpochDay(epoch_seconds{ .secs = sec_unsigned });
        const yr_day = epoch_day.calculateYearDay(day);
        const mon_day = epoch_year_day.calculateMonthDay(yr_day);
        const mon = check_decimal(u4, mon_day.month.numeric()) catch |e| {
            panic("{any}\n", .{e});
        };
        const day_check = check_decimal(u5, mon_day.day_index + 1) catch |e| {
            panic("failed to check day:{any}\n", .{e});
        };
        const mill = std.Io.Timestamp.toMilliseconds(timestamp);
        const mill_sec: i64 = @rem(mill, 1000);
        const m_sec = check_m_sec(mill_sec) catch |e| {
            panic("{any}\n", .{e});
        };
        _ = std.fmt.bufPrint(&buf, "{d}-{s}-{s} {s}:{s}:{s}.{s}", .{ yr_day.year, mon, day_check, hr, min, sec_padded, m_sec }) catch |e| {
            panic("error getting time:{any}\n", .{e});
        };
        return buf;
    }
};

// ===========================================================
// ====================unit test==============================
// ===========================================================

test "create time" {
    defer arena_allocator.deinit();
    var io_threaded = threaded.init(arena_allocator.allocator());
    defer io_threaded.deinit();
    var threaded_io = io_threaded.io();
    const tnow = Time.create(&threaded_io);
    for (0..5) |_| {
        print("{s}\n", .{tnow.now()});
    }
    try std.testing.expect(tnow.now().len == 23);
}

test "day_with_prefix" {
    const d: u5 = 5;
    const day = try check_decimal(u5, d);
    try std.testing.expect(day[0] != 0);
}

test "day_with_no_prefix" {
    const d: u5 = 15;
    const day = try check_decimal(u5, d);
    try std.testing.expect(day[0] != 1);
}

test "m_sec_single_digit" {
    const d: i64 = 9;
    const m_sec = try check_m_sec(d);
    try std.testing.expect(m_sec.len == 3);
}
test "m_sec_single_two_digit" {
    const d: i64 = 10;
    const m_sec = try check_m_sec(d);
    try std.testing.expect(m_sec.len == 3);
}

test "m_sec_single_two_digit_edge" {
    const d: i64 = 99;
    const m_sec = try check_m_sec(d);
    try std.testing.expect(m_sec.len == 3);
}

test "m_sec_single_three_digit_edge" {
    const d: i64 = 100;
    const m_sec = try check_m_sec(d);
    try std.testing.expect(m_sec.len == 3);
}

test "m_sec_single_three_digit" {
    const d: i64 = 101;
    const m_sec = try check_m_sec(d);
    try std.testing.expect(m_sec.len == 3);
}
