//! Place diffs, turns and proof reports.
//!
//! A turn is everything Stud does for one request. Before it touches Studio, the
//! turn is a [`PlaceDiff`]: the instances and scripts it will add, change or remove.
//! The plugin applies an approved diff inside one ChangeHistoryService recording.

use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Op {
    Add,
    Change,
    Remove,
}

impl Op {
    pub fn sign(self) -> char {
        match self {
            Op::Add => '+',
            Op::Change => '~',
            Op::Remove => '−',
        }
    }
}

/// One line of a place diff, for example `+ Workspace.Coins  Folder · 20 parts`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Change {
    pub op: Op,
    /// Full name in the data model, like `ServerScriptService.CoinService`.
    pub path: String,
    /// Short description: the class and size for new instances, `+2 −1` for scripts.
    pub detail: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct PlaceDiff {
    pub changes: Vec<Change>,
}

impl PlaceDiff {
    pub fn push(
        &mut self,
        op: Op,
        path: impl Into<String>,
        detail: impl Into<String>,
    ) -> &mut Self {
        self.changes.push(Change {
            op,
            path: path.into(),
            detail: detail.into(),
        });
        self
    }

    pub fn is_empty(&self) -> bool {
        self.changes.is_empty()
    }

    /// "1 change", "5 changes".
    pub fn summary(&self) -> String {
        match self.changes.len() {
            1 => "1 change".to_string(),
            n => format!("{n} changes"),
        }
    }
}

impl fmt::Display for PlaceDiff {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let width = self
            .changes
            .iter()
            .map(|c| c.path.chars().count())
            .max()
            .unwrap_or(0)
            + 2;
        for c in &self.changes {
            writeln!(f, "{} {:<width$}{}", c.op.sign(), c.path, c.detail)?;
        }
        Ok(())
    }
}

/// What Stud checked after a turn, shown in the terminal and in the Stud panel.
#[derive(Debug, Clone, Default)]
pub struct Proof {
    pub turn: u32,
    pub checks: Vec<Check>,
    pub errors_before: usize,
    pub errors_after: usize,
    pub screenshot: Option<String>,
}

#[derive(Debug, Clone)]
pub struct Check {
    pub passed: bool,
    pub text: String,
}

impl Proof {
    /// A turn only counts as done when every check passed and Output is clean.
    pub fn is_done(&self) -> bool {
        self.errors_after == 0 && !self.checks.is_empty() && self.checks.iter().all(|c| c.passed)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn diff_lines_line_up() {
        let mut diff = PlaceDiff::default();
        diff.push(Op::Add, "Workspace.Lobby", "Model · 26 parts")
            .push(Op::Change, "Workspace.SpawnLocation", "moved into Lobby")
            .push(
                Op::Add,
                "ServerScriptService.CoinService",
                "Script · 48 lines",
            );
        let text = diff.to_string();
        let cols: Vec<usize> = text
            .lines()
            .map(|l| {
                l.find("Model")
                    .or(l.find("moved"))
                    .or(l.find("Script "))
                    .unwrap()
            })
            .collect();
        assert!(cols.windows(2).all(|w| w[0] == w[1]));
        assert_eq!(diff.summary(), "3 changes");
    }

    #[test]
    fn proof_needs_clean_output() {
        let mut proof = Proof {
            turn: 4,
            checks: vec![Check {
                passed: true,
                text: "20 coins spawned".into(),
            }],
            ..Default::default()
        };
        assert!(proof.is_done());
        proof.errors_after = 1;
        assert!(!proof.is_done());
    }
}
