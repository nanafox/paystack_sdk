# AI Skills

The gem ships skills for AI coding agents (Claude Code `SKILL.md` folders) that teach an agent how to use `paystack_sdk` correctly: the conventions, what raises and what returns, and the checks that keep money safe. They are installed from the gem you have, so they match its version.

```sh
# Any Ruby project: installs into ./.claude/skills
bundle exec paystack_sdk skills install

# A Rails app
bin/rails generate paystack_sdk:skills
```

- **Safe to repeat.** A second run reports `identical`. After a gem upgrade, run it again: it updates only the folders it installed.
- **Never overwrites your skills.** Every folder it writes is named `paystack-sdk-<topic>` and carries a `.paystack_sdk.json` marker. A folder with the same name that it did not install is left alone and reported as a `conflict` (`--force` replaces it). It removes only its own folders that a newer gem no longer ships.
- **Version-stamped.** Each installed `SKILL.md` records the gem version in its frontmatter (`metadata.gem_version`).
- Options: `--dir DIR` (another directory), `--global` (`~/.claude/skills`), `--dry-run` (change nothing; `rails generate ... --pretend` in Rails). Other commands: `paystack_sdk skills list`, `skills path` (where the skills live inside the gem, for agents that read files directly), `skills uninstall`, `paystack_sdk version`.

Run `paystack_sdk skills list` for the skills in your installed version and when each one applies. Each is a `paystack-sdk-<topic>` folder; an agent picks them from their descriptions.
