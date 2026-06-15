#!/usr/bin/env python3
"""Single-run version of the monitor for GitHub Actions."""

import os
import hashlib
import json
import logging
import smtplib
import requests
from email.mime.text import MIMEText
from bs4 import BeautifulSoup

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

TOUR_URL       = "https://tour.yeezy.com"
GMAIL_USER     = "knoxtuckeralt@gmail.com"
GMAIL_PASSWORD = os.environ["GMAIL_APP_PASSWORD"]
SMS_GATEWAY    = "9188059498@vtext.com"
STATE_FILE     = "seen_shows.json"

BASELINE_SHOWS = {
    "tampa raymond james stadium 26 june 2026",
    "tampa raymond james stadium 28 june 2026",
    "san antonio 4 july 2026",
    "tirana eagle stadium 11 july 2026",
    "madrid riyadh air metropolitano 30 july 2026",
    "algarve estadio algarve 7 august 2026",
    "chicago soldier field 3 september 2026",
    "chicago soldier field 4 september 2026",
}

HEADERS = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"}


def normalize(text): return " ".join(text.lower().split())
def show_key(text): return hashlib.sha1(normalize(text).encode()).hexdigest()
def is_baseline(text):
    n = normalize(text)
    return any(b in n or n in b for b in BASELINE_SHOWS)

def load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f: return set(json.load(f))
    return {hashlib.sha1(b.encode()).hexdigest() for b in BASELINE_SHOWS}

def save_state(seen):
    with open(STATE_FILE, "w") as f: json.dump(list(seen), f, indent=2)

def scrape_shows():
    resp = requests.get(TOUR_URL, headers=HEADERS, timeout=20)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "html.parser")
    seen_keys, shows = set(), []
    candidates = (soup.select("[class*='show']") + soup.select("[class*='event']")
                  + soup.select("li") + soup.select("tr") + soup.select("article") + soup.select("section"))
    for el in candidates:
        text = el.get_text(" ", strip=True)
        if len(text) < 8 or len(text) > 600: continue
        key = show_key(text)
        if key in seen_keys: continue
        seen_keys.add(key)
        shows.append({"key": key, "text": text})
    return shows

def send_sms(body):
    msg = MIMEText(body)
    msg["From"], msg["To"], msg["Subject"] = GMAIL_USER, SMS_GATEWAY, ""
    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
        smtp.login(GMAIL_USER, GMAIL_PASSWORD)
        smtp.sendmail(GMAIL_USER, SMS_GATEWAY, msg.as_string())
    log.info("SMS sent to %s", SMS_GATEWAY)

seen = load_state()
shows = scrape_shows()
log.info("Found %d show elements.", len(shows))

for show in shows:
    if show["key"] in seen: continue
    if is_baseline(show["text"]):
        seen.add(show["key"]); continue
    log.info("NEW show: %s", show["text"])
    send_sms(f"New Yeezy Tour show added!\n\n{show['text']}\n\nCheck: {TOUR_URL}")
    seen.add(show["key"])

save_state(seen)
