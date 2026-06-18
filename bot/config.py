"""Configuration helpers for the Pickleball Discord bot."""

from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass
class BotConfig:
    """Runtime configuration for the Discord bot."""

    token: str
    command_prefix: str = "!"
    activity_message: str = "Let's play pickleball!"


def load_from_env() -> BotConfig:
    """Load bot configuration from environment variables.

    Raises
    ------
    RuntimeError
        If the ``DISCORD_TOKEN`` environment variable is not present.
    """

    token = os.getenv("DISCORD_TOKEN")
    if not token:
        raise RuntimeError(
            "DISCORD_TOKEN is required to run the Pickleball bot."
        )

    return BotConfig(
        token=token,
        command_prefix=os.getenv("PICKLEBOT_PREFIX", "!"),
        activity_message=os.getenv(
            "PICKLEBOT_ACTIVITY", "Let's play pickleball!"
        ),
    )


__all__ = ["BotConfig", "load_from_env"]
