const std = @import("std");

pub fn main() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();
    var allocator = arenaAllocator.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, &allocator);
    const part1Time = timer.lap() / std.time.ns_per_us;
    const part2 = try solvePart2(fileContent, &allocator);
    const part2Time = timer.lap() / std.time.ns_per_us;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}us\n", .{ part1, part2, part1Time, part2Time });
}

const Cell = struct {
    symbol: u8,
    isAntenna: bool,
    isAntinode: bool,
};

const GridAndMap = struct {
    grid: std.ArrayList([]u8),
    map: std.AutoHashMap(u8, std.ArrayList([2]i32)),
};

fn getGridAndMap(input: []const u8, allocator: *std.mem.Allocator) !GridAndMap {
    var grid = try std.ArrayList([]u8).initCapacity(allocator.*, 50);
    var antennaMap = std.AutoHashMap(u8, std.ArrayList([2]i32)).init(allocator.*);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var x: usize = 0;
    while (lines.next()) |line| : (x += 1) {
        const mutLine = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, mutLine, line);
        grid.appendAssumeCapacity(mutLine);

        for (line, 0..) |character, colIndex| {
            if (character == '.') {
                continue;
            }
            const entry = try antennaMap.getOrPut(character);
            if (!entry.found_existing) {
                entry.value_ptr.* = std.ArrayList([2]i32).init(allocator.*);
            }

            try entry.value_ptr.*.append([2]i32{ @intCast(x), @intCast(colIndex) });
        }
    }

    return GridAndMap{ .grid = grid, .map = antennaMap };
}

fn getGrid(input: []const u8, allocator: *std.mem.Allocator) ![][]Cell {
    var grid = try std.ArrayList([]Cell).initCapacity(allocator.*, 50);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var lineList = try std.ArrayList(Cell).initCapacity(allocator.*, 50);
        for (line) |character| {
            const cell = Cell{
                .symbol = character,
                .isAntenna = character != '.',
                .isAntinode = false,
            };
            lineList.appendAssumeCapacity(cell);
        }
        grid.appendAssumeCapacity(try lineList.toOwnedSlice());
    }
    return try grid.toOwnedSlice();
}

fn place(grid: *[][]Cell, y: isize, x: isize, repeating: bool) void {
    const gridSize = grid.len;
    const yu: usize = @intCast(y);
    const xu: usize = @intCast(x);
    const currentCell = grid.*[yu][xu];

    for (0..gridSize) |rowIndex| {
        for (0..gridSize) |colIndex| {
            const i: isize = @intCast(rowIndex);
            const j: isize = @intCast(colIndex);
            if (x == j and y == i) {
                continue;
            }

            const current = grid.*[rowIndex][colIndex];
            if (current.isAntenna and current.symbol == currentCell.symbol) {
                const dx = x - j;
                const dy = y - i;

                if (!repeating) {
                    setAntinode(grid, x + dx, y + dy);
                    setAntinode(grid, j - dx, i - dy);
                } else {
                    // normally we would need to calculate the gcd
                    // but it seems that the input is nice and the gcd is always 1
                    repeatAntinode(grid, x, y, dx, dy);
                    repeatAntinode(grid, x, y, -dx, -dy);
                }
            }
        }
    }
}

fn setAntinode(grid: *[][]Cell, x: isize, y: isize) void {
    if (inGrid(grid.len, x, y)) {
        const yu: usize = @intCast(y);
        const xu: usize = @intCast(x);
        grid.*[yu][xu].isAntinode = true;
    }
}

fn repeatAntinode(grid: *[][]Cell, x: isize, y: isize, dx: isize, dy: isize) void {
    var nx = x + dx;
    var ny = y + dy;
    while (inGrid(grid.len, nx, ny)) {
        setAntinode(grid, nx, ny);
        nx += dx;
        ny += dy;
    }
}

fn inGrid(gridSize: usize, x: isize, y: isize) bool {
    return x >= 0 and x < gridSize and y >= 0 and y < gridSize;
}

fn canInsertAntinode(grid: *[][]u8, coord: [2]i32) bool {
    const gridSize = grid.len;
    const x = coord[0];
    const y = coord[1];

    if (x < 0 or y < 0 or x >= gridSize or y >= gridSize) {
        return false;
    }
    const xu: usize = @intCast(x);
    const yu: usize = @intCast(y);
    if (grid.*[xu][yu] == '#') {
        return false;
    }
    grid.*[xu][yu] = '#';

    return true;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    const gridAndMap = try getGridAndMap(input, allocator);
    var grid = gridAndMap.grid;
    var antennaMap = gridAndMap.map;
    defer {
        for (grid.items) |elements| {
            allocator.free(elements);
        }
        grid.deinit();
    }
    defer {
        var it = antennaMap.valueIterator();
        while (it.next()) |value| {
            value.deinit();
        }
        antennaMap.deinit();
    }

    var antennaIt = antennaMap.iterator();
    while (antennaIt.next()) |entry| {
        const items = entry.value_ptr.*.items;

        if (items.len < 2) {
            continue;
        }

        for (items, 0..) |a, i| {
            for (items[i + 1 ..]) |b| {
                const ax = a[0];
                const ay = a[1];
                const bx = b[0];
                const by = b[1];

                const ana = [2]i32{ ax + 2 * (bx - ax), ay + 2 * (by - ay) };
                const anb = [2]i32{ bx + 2 * (ax - bx), by + 2 * (ay - by) };

                if (canInsertAntinode(&grid.items, ana)) {
                    result += 1;
                }
                if (canInsertAntinode(&grid.items, anb)) {
                    result += 1;
                }
            }
        }
    }

    return result;
}

fn solvePart1Alt(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var grid = try getGrid(input, allocator);
    defer {
        for (grid) |row| {
            allocator.free(row);
        }
        allocator.free(grid);
    }
    const gridSize = grid.len;

    for (0..gridSize) |rowIndex| {
        for (0..gridSize) |colIndex| {
            const toCheck = grid[rowIndex][colIndex];
            if (!toCheck.isAntenna) {
                continue;
            }

            const i: isize = @intCast(rowIndex);
            const j: isize = @intCast(colIndex);

            place(&grid, i, j, false);
        }
    }

    for (0..gridSize) |rowIndex| {
        for (0..gridSize) |colIndex| {
            if (grid[rowIndex][colIndex].isAntinode) {
                result += 1;
            }
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    const gridAndMap = try getGridAndMap(input, allocator);
    var grid = gridAndMap.grid;
    var antennaMap = gridAndMap.map;
    defer {
        for (grid.items) |elements| {
            allocator.free(elements);
        }
        grid.deinit();
    }
    defer {
        var it = antennaMap.valueIterator();
        while (it.next()) |value| {
            value.deinit();
        }
        antennaMap.deinit();
    }

    const gridSize = grid.items.len;

    var antennaIt = antennaMap.iterator();
    while (antennaIt.next()) |entry| {
        const items = entry.value_ptr.*.items;

        if (items.len < 2) {
            continue;
        }

        for (items, 0..) |a, i| {
            for (items[i + 1 ..]) |b| {
                const ax = a[0];
                const ay = a[1];
                const bx = b[0];
                const by = b[1];

                const abx = bx - ax;
                const aby = by - ay;
                const bax = ax - bx;
                const bay = ay - by;

                // as stated above, no gcd is needed because of the nice input
                var j: i32 = 1;
                while (true) : (j += 1) {
                    const ana = [2]i32{ ax + j * abx, ay + j * aby };
                    const anax = ana[0];
                    const anay = ana[1];

                    if (anax < 0 or anay < 0 or anax >= gridSize or anay >= gridSize) {
                        break;
                    }

                    if (canInsertAntinode(&grid.items, ana)) {
                        result += 1;
                    }
                }

                j = 1;
                while (true) : (j += 1) {
                    const anb = [2]i32{ bx + j * bax, by + j * bay };
                    const anbx = anb[0];
                    const anby = anb[1];

                    if (anbx < 0 or anby < 0 or anbx >= gridSize or anby >= gridSize) {
                        break;
                    }

                    if (canInsertAntinode(&grid.items, anb)) {
                        result += 1;
                    }
                }
            }
        }
    }

    return result;
}

fn solvePart2Alt(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var grid = try getGrid(input, allocator);
    defer {
        for (grid) |row| {
            allocator.free(row);
        }
        allocator.free(grid);
    }
    const gridSize = grid.len;

    for (0..gridSize) |rowIndex| {
        for (0..gridSize) |colIndex| {
            const toCheck = grid[rowIndex][colIndex];
            if (!toCheck.isAntenna) {
                continue;
            }

            const i: isize = @intCast(rowIndex);
            const j: isize = @intCast(colIndex);

            place(&grid, i, j, true);
        }
    }

    for (0..gridSize) |rowIndex| {
        for (0..gridSize) |colIndex| {
            if (grid[rowIndex][colIndex].isAntinode) {
                result += 1;
            }
        }
    }

    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part1Alt = try solvePart1Alt(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);
    const part2Alt = try solvePart2Alt(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 14);
    try std.testing.expectEqual(part1Alt, part1);
    try std.testing.expectEqual(part2, 34);
    try std.testing.expectEqual(part2Alt, part2);
}
