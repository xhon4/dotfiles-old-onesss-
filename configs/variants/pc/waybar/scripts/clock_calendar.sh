#!/bin/bash
# oxh-hyprland-dotfiles by occhi

python3 - <<'EOF'
import datetime, calendar, json, subprocess, shutil, re

now = datetime.date.today()

events_text = []
MAX_LINE = 42 # Strict limit of characters to prevent overflow of the box

if shutil.which("gcalcli"):
    try:
        _, last_day = calendar.monthrange(now.year, now.month)
        start_date = f"{now.year}-{now.month:02d}-01"
        end_date = (datetime.date(now.year, now.month, last_day) + datetime.timedelta(days=1)).strftime("%Y-%m-%d")

        out = subprocess.run(
            ["gcalcli", "schedule", start_date, end_date, "--nocolor", "--nodeclined"],
            capture_output=True, text=True, timeout=8
        ).stdout

        if out:
            clean_out = re.sub(r'\x1b\[[0-9;]*m', '', out)
            for line in clean_out.splitlines():
                line = line.strip()
                if not line: continue
                
                line = re.sub(r'\s{3,}', ' │ ', line)
                
                if len(line) > MAX_LINE:
                    line = line[:MAX_LINE-3] + "..."
                    
                safe_line = line.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                
                events_text.append(f'<span foreground="#BFBFBF" size="smaller">{safe_line}</span>')
    except Exception:
        pass

clean_lines = [re.sub(r'<[^>]+>', '', e) for e in events_text]
max_char_len = max([len(l) for l in clean_lines] + [20])

visual_len = int(max_char_len * 0.85)
pad = " " * max(0, (visual_len - 20) // 2)

cal = calendar.TextCalendar(calendar.MONDAY)
raw_cal = cal.formatmonth(now.year, now.month)

YELLOW  = "#B0B301"
DIM     = "#454343"
FG      = "#FEFEFE"

result_cal = []
for i, line in enumerate(raw_cal.splitlines()):
    if not line: continue
    line = line.ljust(20)
    
    if i == 0:
        result_cal.append(f'{pad}<span foreground="{YELLOW}"><b>{line.strip().center(20)}</b></span>')
    elif i == 1:
        result_cal.append(f'{pad}<span foreground="{DIM}"><b>{line}</b></span>')
    else:
        highlighted = re.sub(
            r'(?<!\d)(' + str(now.day) + r')(?!\d)',
            f'<span foreground="#0C0B05" background="{YELLOW}"><b>\\1</b></span>',
            line,
            count=1
        )
        result_cal.append(f'{pad}<span foreground="{FG}">{highlighted}</span>')

calendar_markup = "\n".join(result_cal)

div_line = "─" * max(20, visual_len)
divider = f'\n<span foreground="{DIM}">{div_line}</span>\n'

if events_text:
    gcal_section = divider + "\n".join(events_text)
else:
    gcal_section = divider + f'<span foreground="{DIM}" size="smaller">without events this month...</span>'

tooltip = f"<tt><span size='10pt'>{calendar_markup}</span>{gcal_section}</tt>"
time_text = datetime.datetime.now().strftime("%I:%M %p").lstrip("0")

print(json.dumps({"text": time_text, "tooltip": tooltip}))
EOF