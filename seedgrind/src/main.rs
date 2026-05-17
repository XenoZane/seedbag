// goal:
// - take in a file with specifications for puzzles
// - determine if solution is unique, or how many solutions there are that adhere to rules.
// - output them.
use std::collections::HashMap;
use std::env;
use std::fs;
use std::io::Write;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: {} <puzzles.txt>", args[0]);
        std::process::exit(1);
    }

    let input = fs::read_to_string(&args[1]).expect("couldn't read input file");
    let puzzles: Vec<Puzzle> = {
        let mut chunks: Vec<String> = Vec::new();
        for line in input.lines() {
            let trimmed = line.trim();
            if trimmed.starts_with(": ") && !trimmed.starts_with(":: ") {
                chunks.push(String::new());
            }
            if let Some(chunk) = chunks.last_mut() {
                chunk.push_str(line);
                chunk.push('\n');
            }
        }
        chunks
            .iter()
            .map(|chunk| parse_one_puzzle(chunk))
            .collect::<Result<Vec<_>, _>>()
    }
    .unwrap();

    let mut failures: Vec<(Puzzle, SolveResult)> = Vec::new();

    for puzzle in puzzles.iter() {
        let result = solve(puzzle);
        let n = result.solutions.len();
        let tried = result.tried;

        match n {
            1 => println!(
                "\x1b[32m[OK] {}: found unique solution, {tried} states tried\x1b[0m",
                puzzle.name
            ),
            0 => println!(
                "\x1b[31m[ERR] {}: found NO solutions out of {tried} tried\x1b[0m",
                puzzle.name
            ),
            _ => {
                println!(
                    "\x1b[31m[ERR] {}: found {n} solutions out of {tried} tried\x1b[0m",
                    puzzle.name
                );
                failures.push((puzzle.clone(), result));
            }
        }
    }

    if !failures.is_empty() {
        write_nonunique(&failures, "nonunique.txt");
    }
}

struct SolveResult {
    solutions: Vec<Grid>,
    tried: usize,
}

fn next_permutation(arr: &mut [Tile]) -> bool {
    let n = arr.len();
    if n <= 1 {
        return false;
    }

    let mut i = n - 1;
    while i > 0 && arr[i - 1] >= arr[i] {
        i -= 1;
    }
    if i == 0 {
        return false;
    }

    let mut j = n - 1;
    while arr[j] <= arr[i - 1] {
        j -= 1;
    }
    arr.swap(i - 1, j);
    arr[i..].reverse();
    true
}

fn solve(puzzle: &Puzzle) -> SolveResult {
    let soil_indices: Vec<usize> = puzzle
        .grid
        .cells
        .iter()
        .enumerate()
        .filter(|(_, t)| **t == Tile::Soil)
        .map(|(i, _)| i)
        .collect();

    // build the multiset: required flowers + Soil padding
    let mut assignment: Vec<Tile> = Vec::new();
    for (&tile, &count) in &puzzle.required_counts {
        for _ in 0..count {
            assignment.push(tile);
        }
    }

    let flowers_needed = assignment.len();
    if flowers_needed > soil_indices.len() {
        eprintln!(
            "  warning: {} needs {} flowers but only {} soil cells",
            puzzle.name,
            flowers_needed,
            soil_indices.len()
        );
        return SolveResult {
            solutions: vec![],
            tried: 0,
        };
    }

    assignment.resize(soil_indices.len(), Tile::Soil);
    assignment.sort();

    let mut result = SolveResult {
        solutions: vec![],
        tried: 0,
    };

    loop {
        result.tried += 1;

        let mut grid = puzzle.grid.clone();
        for (i, &idx) in soil_indices.iter().enumerate() {
            grid.cells[idx] = assignment[i];
        }

        if grid.all_rules_followed() {
            result.solutions.push(grid);
        }

        if !next_permutation(&mut assignment) {
            break;
        }
    }

    result
}

// ── output ──

fn write_nonunique(failures: &[(Puzzle, SolveResult)], path: &str) {
    let mut out = fs::File::create(path).expect("couldn't create output file");

    for (puzzle, result) in failures {
        writeln!(out, ": {}", puzzle.name).unwrap();
        for (&tile, &count) in &puzzle.required_counts {
            if count > 0 {
                writeln!(out, ":: {} {}", tile.flower_name(), count).unwrap();
            }
        }
        write!(out, "{}", puzzle.grid.to_string_grid()).unwrap();

        for (i, sol) in result.solutions.iter().enumerate() {
            writeln!(out, "# --- solution {} ---", i + 1).unwrap();
            for line in sol.to_string_grid().lines() {
                writeln!(out, "# {}", line).unwrap();
            }
        }
        writeln!(out).unwrap();
    }

    eprintln!("wrote nonunique solutions to {path}");
}

#[derive(Debug, Clone)]
pub struct Puzzle {
    pub name: String,
    pub grid: Grid,
    pub required_counts: HashMap<Tile, usize>,
}

pub fn parse_puzzle_grid_character(c: char) -> Result<Tile, String> {
    match c {
        '.' => Ok(Tile::Soil),
        'x' | ' ' => Ok(Tile::Empty),
        'r' => Ok(Tile::Rose),
        's' => Ok(Tile::Sunflower),
        'l' => Ok(Tile::Lavender),
        'g' => Ok(Tile::Glory),
        'W' => Ok(Tile::Wall),
        _ => Err(format!("unknown tile char: '{c}'")),
    }
}

pub fn parse_one_puzzle(input: &str) -> Result<Puzzle, String> {
    let mut name = String::new();
    let mut counts: HashMap<Tile, usize> = HashMap::new();
    let mut rows: Vec<Vec<Tile>> = Vec::new();

    for raw_line in input.lines() {
        let line = raw_line.trim();

        // comment or ignore
        if line.is_empty() || line.starts_with('#') {
            continue;
        // flower amount
        } else if let Some(rest) = line.strip_prefix(":: ") {
            let parts: Vec<&str> = rest.splitn(2, ' ').collect();
            if parts.len() != 2 {
                return Err(format!("bad flower count: {line}"));
            }
            let flower = match parts[0] {
                "rose" => Ok(Tile::Rose),
                "sunflower" => Ok(Tile::Sunflower),
                "lavender" => Ok(Tile::Lavender),
                "glory" => Ok(Tile::Glory),
                _ => Err(format!("unknown flower: '{}'", parts[0])),
            };
            let n: usize = parts[1]
                .parse()
                .map_err(|_| format!("bad count in: {line}"))?;
            counts.insert(flower.unwrap(), n);
        // level name, for readability.
        } else if let Some(rest) = line.strip_prefix(": ") {
            name = rest.to_string();
        // just parse the puzzle.
        } else {
            let row: Vec<Tile> = line
                .chars()
                .map(parse_puzzle_grid_character)
                .collect::<Result<_, _>>()?;
            rows.push(row);
        }
    }

    // error out on empty puzzle
    if rows.is_empty() {
        return Err("no grid rows found".into());
    }

    // get the height; pad the width
    let height = rows.len();
    let width = rows.iter().map(|r| r.len()).max().unwrap_or(0);
    for row in &mut rows {
        row.resize(width, Tile::Empty);
    }

    let cells: Vec<Tile> = rows.into_iter().flatten().collect();

    Ok(Puzzle {
        name,
        grid: Grid {
            cells,
            width,
            height,
        },
        required_counts: counts,
    })
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum Tile {
    Soil,
    Empty,
    Wall,
    Rose,
    Sunflower,
    Lavender,
    Glory,
}

impl Tile {
    fn is_flower(self) -> bool {
        matches!(
            self,
            Tile::Rose | Tile::Sunflower | Tile::Lavender | Tile::Glory
        )
    }

    fn to_char(self) -> char {
        match self {
            Tile::Soil => '.',
            Tile::Empty => ' ',
            Tile::Wall => 'W',
            Tile::Rose => 'r',
            Tile::Sunflower => 's',
            Tile::Lavender => 'l',
            Tile::Glory => 'g',
        }
    }

    fn flower_name(self) -> &'static str {
        match self {
            Tile::Rose => "rose",
            Tile::Sunflower => "sunflower",
            Tile::Lavender => "lavender",
            Tile::Glory => "glory",
            _ => "",
        }
    }
}

#[derive(Debug, Clone)]
pub struct Grid {
    pub cells: Vec<Tile>,
    pub width: usize,
    pub height: usize,
}

const ADJACENTS: [(i32, i32); 4] = [(0, -1), (0, 1), (1, 0), (-1, 0)];

impl Grid {
    pub fn get(&self, x: i32, y: i32) -> Option<Tile> {
        if x < 0 || y < 0 || x >= self.width as i32 || y >= self.height as i32 {
            return None;
        }
        Some(self.cells[y as usize * self.width + x as usize])
    }

    pub fn tile_follows_rule(&self, x: i32, y: i32) -> bool {
        let Some(tile) = self.get(x, y) else {
            return true;
        };

        match tile {
            Tile::Rose => self.check_rose(x, y),
            Tile::Sunflower => self.check_sunflower(x, y),
            Tile::Lavender => self.check_lavender(x, y),
            Tile::Glory => self.check_glory(x, y),
            _ => true,
        }
    }

    fn check_rose(&self, x: i32, y: i32) -> bool {
        // no adjacent roses
        for (dx, dy) in ADJACENTS {
            if self.get(x + dx, y + dy) == Some(Tile::Rose) {
                return false;
            }
        }

        // must see another rose along an axis, unblocked by walls
        let directions: [(i32, i32); 4] = [(-1, 0), (1, 0), (0, -1), (0, 1)];
        for (dx, dy) in directions {
            let (mut cx, mut cy) = (x + dx, y + dy);
            while let Some(t) = self.get(cx, cy) {
                match t {
                    Tile::Wall => break,
                    Tile::Rose => return true,
                    _ => {}
                }
                cx += dx;
                cy += dy;
            }
        }

        false
    }

    fn check_sunflower(&self, x: i32, y: i32) -> bool {
        let left = self.get(x - 1, y) == Some(Tile::Sunflower);
        let right = self.get(x + 1, y) == Some(Tile::Sunflower);
        let up = self.get(x, y - 1) == Some(Tile::Sunflower);
        let down = self.get(x, y + 1) == Some(Tile::Sunflower);

        // no horizontal line of 3+
        if left && right {
            return false;
        }
        // no vertical line of 3+
        if up && down {
            return false;
        }
        // must have at least one neighbor
        if !left && !right && !up && !down {
            return false;
        }

        true
    }

    fn check_lavender(&self, x: i32, y: i32) -> bool {
        // must be interior point of a valid line in at least one axis
        self.check_lavender_axis(x, y, 1, 0) || self.check_lavender_axis(x, y, 0, 1)
    }

    /// finds the full line along `(dx,dy)` and checks if `(x,y)` is a valid interior lavender
    fn check_lavender_axis(&self, x: i32, y: i32, dx: i32, dy: i32) -> bool {
        let line = self.find_lavender_line(x, y, dx, dy);
        self.valid_lavender_line(x, y, &line)
    }

    fn find_lavender_line(&self, x: i32, y: i32, dx: i32, dy: i32) -> Vec<(i32, i32)> {
        let mut line = vec![(x, y)];

        // positive direction
        let (mut cx, mut cy) = (x + dx, y + dy);
        while let Some(t) = self.get(cx, cy) {
            if t.is_flower() {
                line.push((cx, cy));
                if t != Tile::Lavender {
                    break;
                }
            } else {
                break;
            }
            cx += dx;
            cy += dy;
        }

        // negative direction
        let (mut cx, mut cy) = (x - dx, y - dy);
        while let Some(t) = self.get(cx, cy) {
            if t.is_flower() {
                line.insert(0, (cx, cy));
                if t != Tile::Lavender {
                    break;
                }
            } else {
                break;
            }
            cx -= dx;
            cy -= dy;
        }

        line
    }

    fn valid_lavender_line(&self, x: i32, y: i32, line: &[(i32, i32)]) -> bool {
        if line.len() < 3 {
            return false;
        }

        let first = (x, y) != line[0];
        let last = (x, y) != *line.last().unwrap();
        if !first || !last {
            return false;
        }

        // endpoints must be the same flower type (and not lavender — they broke out of the walk)
        let head = self.get(line[0].0, line[0].1).unwrap();
        let tail = self
            .get(line.last().unwrap().0, line.last().unwrap().1)
            .unwrap();
        if head != tail {
            return false;
        }

        // interior must all be lavender
        line[1..line.len() - 1]
            .iter()
            .all(|&(px, py)| self.get(px, py) == Some(Tile::Lavender))
    }

    fn check_glory(&self, x: i32, y: i32) -> bool {
        let mut found_soil = false;
        let mut found_flower = false;

        for (dx, dy) in ADJACENTS {
            match self.get(x + dx, y + dy) {
                Some(Tile::Soil) => found_soil = true,
                Some(t) if t.is_flower() => found_flower = true,
                _ => {}
            }
        }

        found_soil && found_flower
    }

    pub fn all_rules_followed(&self) -> bool {
        for y in 0..self.height as i32 {
            for x in 0..self.width as i32 {
                if !self.tile_follows_rule(x, y) {
                    return false;
                }
            }
        }
        true
    }

    pub fn to_string_grid(&self) -> String {
        let mut s = String::new();
        for y in 0..self.height {
            for x in 0..self.width {
                s.push(self.cells[y * self.width + x].to_char());
            }
            s.push('\n');
        }
        s
    }
}
