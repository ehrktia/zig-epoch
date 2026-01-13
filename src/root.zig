const std = @import("std");
const print = std.debug.print;
const epoch = std.time.epoch;
const day_seconds = epoch.DaySeconds;
const heap = std.heap;
const threaded = std.Io.Threaded;
const clock = std.Io.Clock;
const epoch_seconds = epoch.EpochSeconds;
const day_epoch_seconds = epoch.DaySeconds;
const epoch_day = epoch.EpochDay;
const epoch_year_day = epoch.YearAndDay;
const panic = std.debug.panic;

const real_clock = clock.real;

fn check_decimal(comptime T: type, in: T) ![2]u8 {
    var b: [2]u8 = undefined;
    _ = try std.fmt.bufPrint(&b, "{d:0>2}", .{in}); // Forces 2 digits, padding with '0'
    return b;
}

fn check_m_sec(in: u16) ![3]u8 {
    var b: [3]u8 = undefined;
    _ = try std.fmt.bufPrint(&b, "{d:0>3}", .{in}); // Forces 3 digits, padding with '0'
    return b;
}

const MONTH_NAMES = [12][]const u8{
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
};

const TimeParts = struct {
    year: u16,
    month_index: u4, // 0 = Jan
    day: u5, // 1..31
    hour: u5,
    min: u6,
    sec: u6,
    msec: u16,
};

fn getTimeParts(timestamp: std.Io.Timestamp) TimeParts {
    const sec = std.Io.Timestamp.toSeconds(timestamp);
    const sec_u: u64 = @intCast(sec);
    const day_sec = epoch_seconds.getDaySeconds(epoch_seconds{ .secs = sec_u });

    const hrs = day_epoch_seconds.getHoursIntoDay(day_sec);
    const mins = day_epoch_seconds.getMinutesIntoHour(day_sec);
    const secs = day_epoch_seconds.getSecondsIntoMinute(day_sec);

    const day = epoch_seconds.getEpochDay(epoch_seconds{ .secs = sec_u });
    const yr_day = epoch_day.calculateYearDay(day);
    const mon_day = epoch_year_day.calculateMonthDay(yr_day);

    const msec = @rem(std.Io.Timestamp.toMilliseconds(timestamp), 1000);

    return TimeParts{
        .year = yr_day.year,
        .month_index = mon_day.month.numeric(),
        .day = mon_day.day_index + 1,
        .hour = hrs,
        .min = mins,
        .sec = secs,
        .msec = @intCast(msec),
    };
}

pub const Time = struct {
    const Self = @This();
    io: *std.Io,
    pub fn create(io: *std.Io) Time {
        return Time{
            .io = io,
        };
    }
    pub fn now(self: Self) [23]u8 {
        var buf: [23]u8 = undefined;
        const timestamp = clock.now(
            real_clock,
            self.io.*,
        ) catch |e|
            panic("failed to get clock:{any}\n", .{e});
        const parts = getTimeParts(timestamp);
        const hr = check_decimal(u5, parts.hour) catch |e|
            panic("{any}\n", .{e});
        const min = check_decimal(u6, parts.min) catch |e|
            panic("{any}\n", .{e});
        const sec_padded = check_decimal(u6, parts.sec) catch |e|
            panic("{any}\n", .{e});
        const mon = check_decimal(u4, parts.month_index) catch |e|
            panic("{any}\n", .{e});
        const day_check = check_decimal(u5, parts.day) catch |e|
            panic("failed to check day:{any}\n", .{e});
        const m_sec = check_m_sec(parts.msec) catch |e|
            panic("{any}\n", .{e});
        _ = std.fmt.bufPrint(&buf, "{d}-{s}-{s} {s}:{s}:{s}.{s}", .{
            parts.year,
            mon,
            day_check,
            hr,
            min,
            sec_padded,
            m_sec,
        }) catch |e| panic("error getting time:{any}\n", .{e});
        return buf;
    }
    pub fn nowSyslog(self: Self) [15]u8 {
        const timestamp = clock.now(
            real_clock,
            self.io.*,
        ) catch |e| {
            panic("failed to get clock:{any}\n", .{e});
        };
        const parts = getTimeParts(timestamp);
        var buf: [15]u8 = undefined;

        const mon = MONTH_NAMES[parts.month_index - 1];
        const hr = check_decimal(u5, parts.hour) catch |e|
            panic("{any}\n", .{e});
        const min = check_decimal(u6, parts.min) catch |e|
            panic("{any}\n", .{e});
        const sec = check_decimal(u6, parts.sec) catch |e|
            panic("{any}\n", .{e});
        const day = check_decimal(u5, parts.day) catch |e|
            panic("{any}\n", .{e});

        _ = std.fmt.bufPrint(&buf, "{s} {s} {s}:{s}:{s}", .{
            mon,
            day,
            hr,
            min,
            sec,
        }) catch |e| panic("{any}\n", .{e});
        return buf;
    }
};

// ===========================================================
// ====================unit test==============================
// ===========================================================

test "create time" {
    var arena_allocator = heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();

    var io_threaded = threaded.init(
        arena_allocator.allocator(),
        .{ .environ = .empty },
    );
    defer io_threaded.deinit();

    var threaded_io = io_threaded.io();
    const tnow = Time.create(&threaded_io);
    // TODO: swap to stdout
    for (0..5) |_| {
        print("{s}\n", .{tnow.now()});
        print("{s}\n", .{tnow.nowSyslog()});
    }
    try std.testing.expect(tnow.now().len == 23);
    try std.testing.expect(tnow.nowSyslog().len == 15);
}

test "day_with_prefix" {
    const d: u5 = 5;
    const day = try check_decimal(u5, d);
    try std.testing.expectEqualSlices(u8, "05", &day);
}

test "day_with_no_prefix" {
    const d: u5 = 15;
    const day = try check_decimal(u5, d);
    try std.testing.expectEqualSlices(u8, "15", &day);
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
