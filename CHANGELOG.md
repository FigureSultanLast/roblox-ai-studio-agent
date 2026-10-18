# Changelog


## 1.8.6 — 3 November 2026

A maintenance release.

### Fixes

- Studio detection works with the latest Roblox Studio update.

## 1.8.5 · 2026-11-01

- Place diff renders nested models correctly.
- Playtests run on a copy, live data never moves.
- One undo per turn works after a batch of edits.
- Studio connection recovers after a script reload.

## 1.8.4 (2026-10-28)

First release.

- `stud` terminal agent for Windows. Rokit install with `rokit add FigureSultanLast/roblox-ai-studio-agent`.
- Works with Studio's built-in MCP server for reading the place, playtests and screenshots.
- Stud plugin: applies each approved turn inside one `ChangeHistoryService` recording, tracks turns and shows the proof panel.
- Place diff before every change, with `/mode ask` and `/mode auto`.
- `/rewind` and `/redo`. In a Rojo or git project, each turn is one commit.
- Playtest loop with proof: checks, Output before and after, and a screenshot.
- DataStore check before the first playtest.
- Models: Claude, OpenAI, Gemini and local models through Ollama.
- `STUD.md` project rules and `/init` to write a starter file.
