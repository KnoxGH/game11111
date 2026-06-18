"""Static resources that power the Pickleball Discord bot commands."""

from __future__ import annotations

import random
from typing import Iterable, Sequence


RULES: Sequence[str] = (
    "Pickleball is played either as doubles (two players per team) or singles.",
    "Games are played to 11 points, win by 2, with points scored only on serve.",
    "The serve must be underhand with the paddle below the waist.",
    "The ball must bounce once on each side before volleys are allowed (double bounce rule).",
    "The non-volley zone (kitchen) prohibits volleys when standing inside it.",
)

DRILLS: Sequence[str] = (
    "Dinking warm-up: rally softly in the kitchen focusing on control.",
    "Third-shot drop practice: alternate drives and drops to mix up pace.",
    "Skinny singles: play cross-court points to work on accuracy and footwork.",
    "Serve plus one: serve, then practice a deep third shot to maintain advantage.",
    "Transition drill: move from baseline to kitchen line while keeping the ball in play.",
)

GEAR_RECOMMENDATIONS: Sequence[str] = (
    "Graphite paddle with a polymer core for balanced control and power.",
    "Outdoor-rated pickleballs for play on rougher courts.",
    "Court shoes with non-marking soles to protect the surface and your knees.",
    "Overgrip tape to refresh paddle feel and maintain grip in humid conditions.",
    "A lightweight net system if you're setting up a temporary court.",
)


def format_bulleted(items: Iterable[str]) -> str:
    """Return a Discord-friendly bulleted string."""

    return "\n".join(f"• {item}" for item in items)


def random_choice(options: Sequence[str]) -> str:
    """Return a stable random choice for the command responses."""

    return random.choice(tuple(options))


__all__ = [
    "RULES",
    "DRILLS",
    "GEAR_RECOMMENDATIONS",
    "format_bulleted",
    "random_choice",
]
