//! `stud`: an AI agent in your terminal that builds Roblox places in Studio.

use std::env;
use std::process::ExitCode;

const HELP: &str = "\
stud 1.8.4
Describe it. Stud builds it in Roblox Studio.

Usage:
  stud                      start a session in this folder
  stud \"<request>\"          run one turn and exit
  stud plugin install       copy Stud.rbxm into the Studio plugins folder
  stud login                set a model key, or pick a local model

Options:
  --model <name>            any model id your key allows, or ollama/<model>
  --mode <ask|auto|plan>    ask before changes (default), apply, or plan only
  --studio <id>             pick a Studio window when several are open
  -V, --version             print the version
  -h, --help                print this help
";

fn main() -> ExitCode {
    let args: Vec<String> = env::args().skip(1).collect();
    match args.first().map(String::as_str) {
        Some("-V" | "--version") => {
            println!("stud {}", env!("CARGO_PKG_VERSION"));
            ExitCode::SUCCESS
        }
        Some("-h" | "--help") | None => {
            print!("{HELP}");
            ExitCode::SUCCESS
        }
        Some(other) => {
            eprintln!("stud: unknown command `{other}`. Run `stud --help`.");
            ExitCode::from(2)
        }
    }
}
