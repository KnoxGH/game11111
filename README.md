# Pickleball Discord Bot

A friendly Discord bot that helps your pickleball community stay organized, learn the
basics, and get inspired to play.

## Features

- Quick reference for the most important pickleball rules.
- Random practice drills to keep sessions fresh.
- Gear suggestions for new and experienced players alike.
- Automated practice planner with themed focuses.
- Roll-call command so members can react and RSVP to meetups.

## Getting started

1. Create a Discord application and bot account at the
   [Discord Developer Portal](https://discord.com/developers/applications).
2. Install dependencies:

   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. Set the required environment variables. At minimum you must provide your bot token:

   ```bash
   export DISCORD_TOKEN="your bot token"
   # Optional overrides
   export PICKLEBOT_PREFIX="!"  # Command prefix
   export PICKLEBOT_ACTIVITY="Heading to the courts"  # Custom status text
   ```

4. Invite the bot to your server using the OAuth2 URL generator with the bot scope and
   the ``Send Messages`` and ``Add Reactions`` permissions.
5. Run the bot:

   ```bash
   python -m bot
   ```

## Available commands

| Command | Description |
| ------- | ----------- |
| `!rules` | Display a refresher on essential pickleball rules. |
| `!drill` | Get a randomly selected drill to try during your next practice. |
| `!gear`  | Share a curated list of recommended pickleball equipment. |
| `!plan [focus]` | Generate a session agenda for the chosen focus (balanced, doubles, singles, serves, defense). |
| `!rollcall <session>` | Ask who can attend a session and collect reactions automatically. |

Feel free to modify the command handlers in [`bot/picklebot.py`](bot/picklebot.py) to
customize the bot for your community.
