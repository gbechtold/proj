#!/usr/bin/env python3
"""proj JSON helper — safe JSON operations for zsh."""

import json
import sys
import os
from datetime import datetime


def load(filepath):
    try:
        with open(filepath) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save(filepath, data):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def now_iso():
    return datetime.now().strftime("%Y-%m-%dT%H:%M:%S")


def main():
    if len(sys.argv) < 3:
        print("Usage: proj_helper.py <file> <op> [args...]", file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    op = sys.argv[2]
    args = sys.argv[3:]
    data = load(filepath)

    # --- get <key> [subkey] ---
    if op == "get":
        val = data
        for key in args:
            if isinstance(val, dict):
                val = val.get(key, "")
            elif isinstance(val, list):
                try:
                    val = val[int(key)]
                except (IndexError, ValueError):
                    val = ""
                    break
            else:
                val = ""
                break
        if isinstance(val, (dict, list)):
            print(json.dumps(val, ensure_ascii=False))
        else:
            print(val)

    # --- set <key> <value> ---
    elif op == "set":
        key, value = args[0], args[1]
        try:
            data[key] = json.loads(value)
        except json.JSONDecodeError:
            data[key] = value
        data["updated"] = now_iso()
        save(filepath, data)

    # --- set-nested <key> <subkey> <value> ---
    elif op == "set-nested":
        key, subkey, value = args[0], args[1], args[2]
        if key not in data or not isinstance(data[key], dict):
            data[key] = {}
        data[key][subkey] = value
        data["updated"] = now_iso()
        save(filepath, data)

    # --- delete-nested <key> <subkey> ---
    elif op == "delete-nested":
        key, subkey = args[0], args[1]
        if key in data and isinstance(data[key], dict):
            data[key].pop(subkey, None)
        data["updated"] = now_iso()
        save(filepath, data)

    # --- append <key> <value-json> ---
    elif op == "append":
        key, value = args[0], args[1]
        if key not in data or not isinstance(data[key], list):
            data[key] = []
        try:
            data[key].append(json.loads(value))
        except json.JSONDecodeError:
            data[key].append(value)
        data["updated"] = now_iso()
        save(filepath, data)

    # --- pop-list <key> <index> ---
    elif op == "pop-list":
        key, idx = args[0], int(args[1])
        if key in data and isinstance(data[key], list) and 0 <= idx < len(data[key]):
            data[key].pop(idx)
        data["updated"] = now_iso()
        save(filepath, data)

    # --- list-keys [key] ---
    elif op == "list-keys":
        target = data
        if args:
            target = data.get(args[0], {})
        if isinstance(target, dict):
            for k in target:
                print(k)

    # --- count <key> ---
    elif op == "count":
        val = data.get(args[0], [])
        print(len(val) if isinstance(val, (list, dict)) else 0)

    # --- dump ---
    elif op == "dump":
        print(json.dumps(data, indent=2, ensure_ascii=False))

    # --- init <name> [color] ---
    elif op == "init":
        if not data:
            data = {
                "name": args[0] if args else "Unnamed",
                "color": args[1] if len(args) > 1 else "",
                "task": "",
                "notes": [],
                "links": {},
                "time": [],
                "ai": {},
                "created": now_iso(),
                "updated": now_iso(),
            }
            save(filepath, data)
            print("created")
        else:
            print("exists")

    # --- migrate-conf <conf-file> ---
    elif op == "migrate-conf":
        conf_path = args[0]
        if not os.path.isfile(conf_path):
            print("not_found", file=sys.stderr)
            sys.exit(1)

        name = color = task = ""
        notes = []
        with open(conf_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith("name="):
                    name = line[5:]
                elif line.startswith("color="):
                    color = line[6:]
                elif line.startswith("task="):
                    task = line[5:]
                elif line.startswith("note="):
                    notes.append(line[5:])

        data = {
            "name": name,
            "color": color,
            "task": task,
            "notes": notes,
            "links": {},
            "time": [],
            "ai": {},
            "created": now_iso(),
            "updated": now_iso(),
        }
        save(filepath, data)
        print(f"migrated:{name}")

    # --- time-start ---
    elif op == "time-start":
        if "time" not in data or not isinstance(data["time"], list):
            data["time"] = []
        # Check if there's already a running timer
        for entry in data["time"]:
            if isinstance(entry, dict) and entry.get("start") and not entry.get("stop"):
                print(f"running:{entry['start']}")
                sys.exit(0)
        data["time"].append({"start": now_iso(), "stop": None})
        data["updated"] = now_iso()
        save(filepath, data)
        print(f"started:{now_iso()}")

    # --- time-stop ---
    elif op == "time-stop":
        if "time" not in data or not isinstance(data["time"], list):
            print("no_timer")
            sys.exit(0)
        for entry in reversed(data["time"]):
            if isinstance(entry, dict) and entry.get("start") and not entry.get("stop"):
                entry["stop"] = now_iso()
                data["updated"] = now_iso()
                save(filepath, data)
                # Calculate duration
                start = datetime.fromisoformat(entry["start"])
                stop = datetime.fromisoformat(entry["stop"])
                delta = stop - start
                hours, remainder = divmod(int(delta.total_seconds()), 3600)
                minutes = remainder // 60
                print(f"stopped:{entry['start']}:{entry['stop']}:{hours}h {minutes}m")
                sys.exit(0)
        print("no_timer")

    # --- time-status ---
    elif op == "time-status":
        if "time" in data and isinstance(data["time"], list):
            for entry in reversed(data["time"]):
                if isinstance(entry, dict) and entry.get("start") and not entry.get("stop"):
                    start = datetime.fromisoformat(entry["start"])
                    delta = datetime.now() - start
                    hours, remainder = divmod(int(delta.total_seconds()), 3600)
                    minutes = remainder // 60
                    print(f"running:{entry['start']}:{hours}h {minutes}m")
                    sys.exit(0)
        print("idle")

    # --- time-log [days] ---
    elif op == "time-log":
        days = int(args[0]) if args else 30
        cutoff = datetime.now().replace(hour=0, minute=0, second=0)
        from datetime import timedelta
        cutoff = cutoff - timedelta(days=days)

        entries = data.get("time", [])
        total_seconds = 0
        results = []

        for entry in entries:
            if not isinstance(entry, dict) or not entry.get("start"):
                continue
            start = datetime.fromisoformat(entry["start"])
            if start < cutoff:
                continue
            stop_str = entry.get("stop", "")
            if stop_str:
                stop = datetime.fromisoformat(stop_str)
                delta = int((stop - start).total_seconds())
                total_seconds += delta
                hours, remainder = divmod(delta, 3600)
                minutes = remainder // 60
                results.append(f"{start.strftime('%Y-%m-%d')}|{start.strftime('%H:%M')}|{stop.strftime('%H:%M')}|{hours}h {minutes:02d}m")
            else:
                results.append(f"{start.strftime('%Y-%m-%d')}|{start.strftime('%H:%M')}|running|--")

        # Print results
        for r in results:
            print(r)

        # Print total
        hours, remainder = divmod(total_seconds, 3600)
        minutes = remainder // 60
        print(f"TOTAL|{hours}h {minutes:02d}m|{len(results)} entries")

    else:
        print(f"Unknown operation: {op}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
