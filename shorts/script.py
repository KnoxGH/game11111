from __future__ import annotations

from dataclasses import dataclass
from textwrap import dedent


@dataclass
class Script:
    idea: str
    title: str
    lines: tuple[str, ...]

    def to_text(self) -> str:
        return "\n".join(self.lines)

    def to_caption_blocks(self, words_per_line: int = 8) -> list[tuple[int, int, str]]:
        blocks: list[tuple[int, int, str]] = []
        start = 0
        for index, line in enumerate(self.lines):
            words = line.split()
            line_words: list[str] = []
            for word in words:
                line_words.append(word)
                if len(line_words) >= words_per_line:
                    segment = " ".join(line_words)
                    blocks.append((start, start + 3, segment))
                    start += 3
                    line_words = []
            if line_words:
                segment = " ".join(line_words)
                blocks.append((start, start + 3, segment))
                start += 3
        if not blocks:
            blocks.append((0, 3, self.title))
        return blocks


def draft_script(idea: str) -> Script:
    hook = idea.strip().rstrip(".")
    title = f"{hook} in 30 seconds"
    body = dedent(
        f"""
        Here is the story in three beats about {hook}:
        1) The setup: what is it?
        2) The twist: why should you care?
        3) The takeaway: how to try it today.
        """
    ).strip()
    beats = tuple(
        line.strip()
        for line in body.splitlines()
        if line.strip()
    )
    return Script(idea=idea, title=title, lines=beats)
