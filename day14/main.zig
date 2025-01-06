const std = @import("std");

pub fn main() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();
    var allocator = arenaAllocator.allocator();
    const fileContent = @embedFile("input.txt");

    const boardSizes = [2]isize{ 101, 103 };
    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(boardSizes, fileContent);
    const part1Time = timer.lap() / std.time.ns_per_us;
    const part2 = try solvePart2(boardSizes, fileContent, &allocator);
    const part2Time = timer.lap() / std.time.ns_per_us;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}us\n", .{ part1, part2, part1Time, part2Time });
}

fn solvePart1(comptime boardSizes: [2]isize, input: []const u8) !usize {
    var quadrants: [4]usize = std.mem.zeroes([4]usize);
    const boardWidth = boardSizes[0];
    const boardHeight = boardSizes[1];

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var segments = std.mem.tokenizeScalar(u8, line, ' ');
        const positionSegment = segments.next().?;
        const velocitySegment = segments.next().?;

        const commaPosition = std.mem.indexOfScalarPos(u8, positionSegment, 2, ',');
        const commaPosPosition = commaPosition.?;
        const positionX = try std.fmt.parseInt(isize, positionSegment[2..commaPosPosition], 10);
        const positionY = try std.fmt.parseInt(isize, positionSegment[commaPosPosition + 1 .. positionSegment.len], 10);

        const commaVelocity = std.mem.indexOfScalarPos(u8, velocitySegment, 2, ',');
        const commaVelocityPosition = commaVelocity.?;
        const velX = try std.fmt.parseInt(isize, velocitySegment[2..commaVelocityPosition], 10);
        const velY = try std.fmt.parseInt(isize, velocitySegment[commaVelocityPosition + 1 .. velocitySegment.len], 10);

        var x = @mod((positionX + velX * 100), boardWidth);
        if (x < 0) {
            x += boardWidth;
        }

        var y = @mod((positionY + velY * 100), boardHeight);
        if (y < 0) {
            y += boardHeight;
        }

        const middleWidth = (boardWidth - 1) / 2;
        const left = x < middleWidth;
        const right = x > middleWidth;
        const middleHeight = (boardHeight - 1) / 2;
        const top = y < middleHeight;
        const bottom = y > middleHeight;
        if (left) {
            if (top) {
                quadrants[0] += 1;
            }
            if (bottom) {
                quadrants[2] += 1;
            }
            continue;
        }

        if (right) {
            if (top) {
                quadrants[1] += 1;
            }
            if (bottom) {
                quadrants[3] += 1;
            }
        }
    }

    const result = quadrants[0] * quadrants[1] * quadrants[2] * quadrants[3];
    return result;
}

fn solvePart2(comptime boardSizes: [2]isize, input: []const u8, allocator: *std.mem.Allocator) !usize {
    const boardWidth = boardSizes[0];
    const boardHeight = boardSizes[1];

    var positionListX = try std.ArrayList(i8).initCapacity(allocator.*, 500);
    var positionListY = try std.ArrayList(i8).initCapacity(allocator.*, 500);
    var velocityListX = try std.ArrayList(i8).initCapacity(allocator.*, 500);
    var velocityListY = try std.ArrayList(i8).initCapacity(allocator.*, 500);

    defer {
        positionListX.deinit();
        positionListY.deinit();
        velocityListX.deinit();
        velocityListY.deinit();
    }

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var segments = std.mem.tokenizeScalar(u8, line, ' ');
        const positionSegment = segments.next().?;
        const velocitySegment = segments.next().?;

        const commaPosition = std.mem.indexOfScalarPos(u8, positionSegment, 2, ',');
        const commaPosPosition = commaPosition.?;
        const positionX = try std.fmt.parseInt(i8, positionSegment[2..commaPosPosition], 10);
        const positionY = try std.fmt.parseInt(i8, positionSegment[commaPosPosition + 1 .. positionSegment.len], 10);
        positionListX.appendAssumeCapacity(positionX);
        positionListY.appendAssumeCapacity(positionY);

        const commaVelocity = std.mem.indexOfScalarPos(u8, velocitySegment, 2, ',');
        const commaVelocityPosition = commaVelocity.?;
        const velocityX = try std.fmt.parseInt(i8, velocitySegment[2..commaVelocityPosition], 10);
        const velocityY = try std.fmt.parseInt(i8, velocitySegment[commaVelocityPosition + 1 .. velocitySegment.len], 10);
        velocityListX.appendAssumeCapacity(velocityX);
        velocityListY.appendAssumeCapacity(velocityY);
    }

    const tx = clustered(&positionListX, &velocityListX, boardWidth);
    const ty = clustered(&positionListY, &velocityListY, boardHeight);

    // inv{a} (mod m) = b, if a * b = 1 (mod m)
    // inv{101} (mod 103) = 51, because 101 * 51 = 5151 = 1 (mod 103)
    const INVX: isize = 51;
    const t = tx + @mod(INVX * (ty - tx + boardHeight), boardHeight) * boardWidth;

    return @intCast(t);
}

fn clustered(positionList: *std.ArrayList(i8), velocityList: *std.ArrayList(i8), comptime mod: isize) isize {
    const robots: isize = @intCast(positionList.items.len);
    var tMin: isize = -1;
    var varianceMin: isize = std.math.maxInt(isize);
    var t: isize = 0;
    while (t < mod) : (t += 1) {
        var sum: isize = 0;
        var sum2: isize = 0;
        var i: usize = 0;
        while (i < robots) : (i += 1) {
            const q = @mod((positionList.*.items[i] + (velocityList.*.items[i] + mod) * t), mod);
            sum += q;
            sum2 += q * q;
        }

        const variance = @divFloor((sum2 - sum * @divFloor(sum, robots)), robots);
        if (variance < varianceMin) {
            varianceMin = variance;
            tMin = t;
        }
    }
    return tMin;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");
    const boardSizes = [2]isize{ 11, 7 };

    const part1 = try solvePart1(boardSizes, fileContentTest);
    const part2 = try solvePart2(boardSizes, fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 12);
    try std.testing.expectEqual(part2, 45);
}
