import argparse
from dataclasses import dataclass

import z3

SOIL = 0
ROSE = 1
SUNFLOWER = 2
LAVENDER = 3
GLORY = 4
EMPTY = 5
FLOWERS = [ROSE, SUNFLOWER, LAVENDER, GLORY]

CHAR_TO_TILE = {
    ".": SOIL,
    "r": ROSE,
    "s": SUNFLOWER,
    "l": LAVENDER,
    "g": GLORY,
    "x": EMPTY,
    " ": EMPTY,
}
TILE_TO_CHAR = {
    SOIL: ".",
    ROSE: "r",
    SUNFLOWER: "s",
    LAVENDER: "l",
    GLORY: "g",
    EMPTY: " ",
}


NAME_TO_TILE = {
    "rose": ROSE,
    "sunflower": SUNFLOWER,
    "lavender": LAVENDER,
    "glory": GLORY,
}
TILE_TO_NAME = {v: k for k, v in NAME_TO_TILE.items()}

YELLOW = '\033[33m'
GREEN = '\033[32m'
RED = '\033[31m'
RESET = '\033[0m'


@dataclass
class Puzzle:
    name: str
    counts: dict[int, int]
    grid: list[list[int]]
    width: int
    height: int


def solve(puzzle: Puzzle) -> list[dict]:
    grid = puzzle.grid
    w, h = puzzle.width, puzzle.height
    counts = puzzle.counts

    available_flowers = [f for f in FLOWERS if f in counts.keys()]
    # all_flowers = list(set(available_flowers).union(set(f for f in FLOWERS if any(f in row for row in grid))))
    
    solver = z3.Solver()
    cells = {}

    # constraint: soil can be soil or available flower, all other cells unchanged.
    # setup `cells` to reflect this.
    for y in range(h):
        for x in range(w):
            v = grid[y][x]
            if v == SOIL:
                c = z3.Int(f"c_{x}_{y}")
                cells[(x, y)] = c
                solver.add(z3.Or([c == typ for typ in [SOIL] + available_flowers]))
            else:
                cells[(x, y)] = z3.IntVal(v)

    # get valid cell
    # returning None to be more sensible for constraint checking.
    def cell(x, y):
        return cells[(x, y)] if 0 <= x < w and 0 <= y < h else None

    # iterate over adjacent positions which exist
    def adjacents(x, y):
        for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
            c = cell(x + dx, y + dy)
            if c is not None:
                yield cell(x + dx, y + dy)

    # constraint: must place exactly the count of each flower on a soil.
    # pseudo-boolean: sum of truth/false (mapped 1/0) must be `count`.
    soils = [cells[(x, y)] for y in range(h) for x in range(w) if grid[y][x] == SOIL]
    for tile, count in counts.items():
        solver.add(z3.PbEq([(soil == tile, 1) for soil in soils], count))

    # constraints: flower rules.
    for y in range(h):
        for x in range(w):
            c = cell(x, y)

            # rose rules:
            # - no adjacent roses
            # - must be a rose in the same row/column (not including self)
            rose_constraints = []
            for c2 in adjacents(x, y):
                rose_constraints.append(c2 != ROSE)

            line_constraints = []
            row = [cell(xx, y) for xx in range(w) if xx != x]
            col = [cell(x, yy) for yy in range(h) if yy != y]
            for c2 in row:
                line_constraints.append(c2 == ROSE)
            for c2 in col:
                line_constraints.append(c2 == ROSE)
            rose_constraints.append(z3.Or(line_constraints) if line_constraints else False)
                
            solver.add(z3.Implies(c == ROSE, z3.And(rose_constraints)))

            # sunflower rules:
            # - must have an adjacent sunflower
            # - must not have sunflowers on both horz neighbors or both vert neighbors.
            sunflower_constraints = []
            neighbor_constraints = []
            for c2 in adjacents(x, y):
                neighbor_constraints.append(c2 == SUNFLOWER)
            sunflower_constraints.append(z3.Or(neighbor_constraints))

            left = cell(x - 1, y)
            right = cell(x + 1, y)
            up = cell(x, y - 1)
            down = cell(x, y + 1)

            if left is not None and right is not None:
                sunflower_constraints.append(z3.Not(z3.And(left == SUNFLOWER, right == SUNFLOWER)))
            if up is not None and down is not None:
                sunflower_constraints.append(z3.Not(z3.And(up == SUNFLOWER, down == SUNFLOWER)))

            solver.add(z3.Implies(c == SUNFLOWER, z3.And(sunflower_constraints)))

            # lavender rules..
            # - must be an interior point in a line of 3+ flowers where the ends are the same flower.
            if grid[y][x] == SOIL or grid[y][x] == LAVENDER:
                lavender_constraints = []
                for dx, dy in [(1, 0), (0, 1)]:
                    # 1. get the max line this cell is a part of which is bookended by soil.
                    line = []

                    lx, ly = x, y
                    while 0 <= lx < w and 0 <= ly < h and grid[ly][lx] != EMPTY:
                        line.append((lx, ly))
                        lx -= dx
                        ly -= dy
                    line.reverse()

                    lx, ly = x + dx, y + dy
                    while 0 <= lx < w and 0 <= ly < h and grid[ly][lx] != EMPTY:
                        line.append((lx, ly))
                        lx += dx
                        ly += dy

                    # 2. get every sub-line containing this cell.
                    # eg. i < cell_idx < j
                    # so all lines necessarily 3+ elements long
                    # where cell_idx is between a start and end.
                    cell_idx = line.index((x, y))
                    for lo in range(cell_idx):
                        for hi in range(cell_idx + 1, len(line)):
                            if hi - lo < 2:
                                print("how can this happen?")
                                continue
                            exterior_a = cell(*line[lo])
                            exterior_b = cell(*line[hi])
                            interiors = [cell(*line[mid]) for mid in range(lo + 1, hi)]
                            for f in FLOWERS:
                                lavender_constraints.append(
                                    z3.And(
                                       exterior_a == f,
                                       exterior_b == f,
                                       *[interior == LAVENDER for interior in interiors] 
                                    )
                                )

                # 3. if any such line satisfies, flower is ok (note the Or).
                if lavender_constraints:
                    solver.add(z3.Implies(c == LAVENDER, z3.Or(lavender_constraints)))
                else:
                    solver.add(c != LAVENDER)

        
            # glory rules:
            # - must have an adjacent flower
            # - must have an adjacent soil
            ns = list(adjacents(x, y))
            if ns:
                solver.add(z3.Implies(
                    c == GLORY,
                    # TODO: can the second case here just be an `in`?
                    # it could definitely be a range check.
                    z3.And(
                        z3.Or([n == SOIL for n in ns]),
                        z3.Or([z3.Or([n == f for f in FLOWERS]) for n in ns])
                    )
                ))
            else:
                solver.add(c != GLORY)

    solutions = []

    while True:
        if solver.check() == z3.sat:
            m = solver.model()
            sol = {}
            for y in range(h):
                for x in range(w):
                    # TODO: do we need to do this? dont we set intvars?
                    if grid[y][x] == SOIL:
                        sol[(x, y)] = m[cells[(x, y)]].as_long() # TODO: why?
                    else:
                        sol[(x, y)] = grid[y][x]
            solutions.append(sol)

            # exclude the solution we just found.
            solver.add(z3.Or([
                cells[(x, y)] != sol[(x, y)]
                for y in range(h) for x in range(w)
                if grid[y][x] == SOIL
                                 
            ]))
        else:
            break
    
    
    return solutions
    


def main():
    parser = argparse.ArgumentParser(prog="seedgrind.py")
    parser.add_argument("puzzle_file")
    # parser.add_argument("-n", "--name", help="specific puzzle from file to test")

    args = parser.parse_args()

    # parse out puzzles:
    # : name
    # :: count <int>
    # # comment
    # everything else grid
    #
    # # newline as above will start a new puzzle (newline sensitive...)
    with open(args.puzzle_file) as f:
        lines = f.readlines()
    
    puzzles = []

    name = ""
    counts = {}
    rows = []

    for line in lines:
        line = line.rstrip('\n')

        if line.startswith("#"):
            continue

        if not line:
            assert(name)
            assert(len(counts) > 0)
            assert(len(rows) > 0)
            max_width = max(len(r) for r in rows)
            for r in rows:
                r.extend([EMPTY] * (max_width - len(r)))
            puzzles.append(
                Puzzle(
                    name=name,
                    counts=counts.copy(),
                    grid=rows.copy(),
                    width=max_width,
                    height=len(rows),
                )
            )

            name = ""
            counts.clear()
            rows.clear()

        if line.startswith(": "):
            name = line[2:]
        elif line.startswith(":: "):
            parts = line[3:].split(None, 1)
            tool_name = parts[0]
            tool_count = int(parts[1])
            tile = NAME_TO_TILE[tool_name]
            counts[tile] = tool_count
        else:
            rows.append([CHAR_TO_TILE[c] for c in line])

    # final puzzle should be available after parsing.
    assert(name)
    assert(len(counts) > 0)
    assert(len(rows) > 0)
    max_width = max(len(r) for r in rows)
    for r in rows:
        r.extend([EMPTY] * (max_width - len(r)))
    puzzles.append(
        Puzzle(
            name=name,
            counts=counts.copy(),
            grid=rows.copy(),
            width=max_width,
            height=len(rows),
        )
    )

    failures = []
    for puzzle in puzzles:
        solutions = solve(puzzle)
        if len(solutions) == 1:
            print(f"{GREEN}[OK] {puzzle.name}: unique solution found.{RESET}")
        elif len(solutions) == 0:
            print(f"{RED}[ERR] {puzzle.name}: no solution found.{RESET}")
        else:
            print(f"{RED}[ERR] {puzzle.name}: {len(solutions)} solutions found.{RESET}")
            failures.append((puzzle, solutions))

    if failures:
        with open('nonunique.txt', 'w') as f:
            for puzzle, solns in failures:
                lines = [f": {puzzle.name}"]
                for tile, count in puzzle.counts.items():
                    lines.append(f":: {TILE_TO_NAME[tile]} {count}")
                for row in puzzle.grid:
                    lines.append("".join(TILE_TO_CHAR[tile] for tile in row))
                header = "\n".join(lines)
                f.write(header + '\n')
                for idx, soln in enumerate(solns):
                    f.write(f"# --- solution {idx + 1} ---")
                    for y in range(puzzle.height):
                        line = "".join(TILE_TO_CHAR[soln[(x, y)]] for x in range(puzzle.width))
                        f.write(f"# {line}\n")
                f.write('\n')
        print("wrote nonunique solutions to nonunique.txt")

if __name__ == "__main__":
    main()
