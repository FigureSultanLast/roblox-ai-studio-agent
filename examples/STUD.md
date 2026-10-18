# STUD.md

Stud reads this file before every turn in this place. Keep it short and specific.

## Layout

- Server code lives in `ServerScriptService/Services`, one ModuleScript per service. Don't add plain Scripts there.
- Remotes live in `ReplicatedStorage/Remotes` and are created in code, never by hand.
- Shared modules go in `ReplicatedStorage/Shared`.

## Style

- Every new script starts with `--!strict`.
- Use attributes for tuning values (coin value, respawn time), not IntValues.
- No `wait()`. Use `task.wait()`.

## Hands off

- Don't touch `Workspace.Map`. Our level designer builds it by hand.
- Never publish. If a change needs a publish, say so in the terminal.

## Playtests

- A good test walk collects at least 3 coins and opens the VIP door once.
