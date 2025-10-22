"""Discord bot that helps organize and inspire pickleball play."""

from __future__ import annotations

import textwrap
from typing import Dict

import discord
from discord.ext import commands

from .config import BotConfig
from .resources import (
    DRILLS,
    GEAR_RECOMMENDATIONS,
    RULES,
    format_bulleted,
    random_choice,
)

SESSION_FOCUS: Dict[str, str] = {
    "balanced": "A mix of dinking, third-shot drops, and transition play.",
    "doubles": "Team communication drills, stacking practice, and kitchen control games.",
    "singles": "Skinny singles, deep serves, and sideline accuracy challenges.",
    "serves": "Target serving with alternating spin and placement goals.",
    "defense": "Reset drills, lob defense, and block volleys to regain control.",
}


def create_bot(config: BotConfig) -> commands.Bot:
    """Create the configured Discord bot instance."""

    intents = discord.Intents.default()
    intents.message_content = True

    bot = commands.Bot(
        command_prefix=config.command_prefix,
        intents=intents,
        description="A helpful assistant for pickleball communities.",
    )

    activity = discord.Game(name=config.activity_message)

    @bot.event
    async def on_ready() -> None:  # type: ignore[override]
        if bot.user is None:
            return
        await bot.change_presence(activity=activity)
        print(f"{bot.user} has connected to Discord and is ready to rally!")

    @bot.event
    async def on_command_error(
        ctx: commands.Context, error: commands.CommandError
    ) -> None:
        if isinstance(error, commands.MissingRequiredArgument):
            command = ctx.command.qualified_name if ctx.command else "command"
            await ctx.send(
                f"⚠️ Missing argument `{error.param.name}` for `{config.command_prefix}{command}`."
            )
            return
        raise error

    @bot.command(help="Show a quick refresher on the core pickleball rules.")
    async def rules(ctx: commands.Context) -> None:
        embed = discord.Embed(
            title="Pickleball Basics",
            description=format_bulleted(RULES),
            colour=discord.Colour.green(),
        )
        embed.set_footer(text="Remember: win by two and have fun!")
        await ctx.send(embed=embed)

    @bot.command(help="Get a randomly selected drill to spice up practice sessions.")
    async def drill(ctx: commands.Context) -> None:
        await ctx.send(
            embed=discord.Embed(
                title="Practice Drill",
                description=random_choice(DRILLS),
                colour=discord.Colour.orange(),
            )
        )

    @bot.command(help="Suggestions for gear to bring to your next pickleball meetup.")
    async def gear(ctx: commands.Context) -> None:
        await ctx.send(
            embed=discord.Embed(
                title="Recommended Gear",
                description=format_bulleted(GEAR_RECOMMENDATIONS),
                colour=discord.Colour.blurple(),
            )
        )

    @bot.command(
        name="plan",
        help="Create a themed practice plan. Usage: !plan [focus]",
    )
    async def plan(ctx: commands.Context, *, focus: str = "balanced") -> None:
        normalized = focus.lower().strip()
        key = normalized if normalized in SESSION_FOCUS else "balanced"
        summary = SESSION_FOCUS[key].rstrip(".")
        agenda = textwrap.dedent(
            f"""
            **Focus:** {key.title()}
            • Warm-up: 5 minutes of cooperative dinking.
            • Drills: 15 minutes dedicated to {summary.lower()}.
            • Games: King/Queen of the Court rotation to finish strong.
            """
        ).strip()

        await ctx.send(
            embed=discord.Embed(
                title="Practice Planner",
                description=agenda,
                colour=discord.Colour.teal(),
            )
        )

    @bot.command(help="Check in to find partners. Usage: !rollcall Saturday 9am")
    async def rollcall(ctx: commands.Context, *, session: str) -> None:
        message = textwrap.dedent(
            f"""
            **Who's in?**
            {ctx.author.mention} wants to rally for **{session}**.
            React with ✅ if you can play or 🤔 if you're a maybe!
            """
        ).strip()

        sent = await ctx.send(message)
        for emoji in ("✅", "🤔", "❌"):
            await sent.add_reaction(emoji)

    return bot


def main() -> None:
    """Entry point for running the bot directly."""

    from .config import load_from_env

    config = load_from_env()
    bot = create_bot(config)
    bot.run(config.token)


if __name__ == "__main__":
    main()
