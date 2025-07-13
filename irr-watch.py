#!/usr/bin/env python3

import os
import sys
import subprocess
import time

VENV_DIR = ".venv_irr-watch"
OUTPUT_DIR = ".irr-query-results"
GITIGNORE_PATH = ".gitignore"

VENV_PATH = os.path.join(os.getcwd(), VENV_DIR)
OUTPUT_PATH = os.path.join(os.getcwd(), OUTPUT_DIR)

def venv_is_stale(path, max_age_sec=86400):
    if not os.path.exists(path):
        return True
    return (time.time() - os.path.getmtime(path)) > max_age_sec

def create_or_refresh_venv():
    if venv_is_stale(VENV_PATH):
        print("Creating or refreshing Python venv...")
        if os.path.exists(VENV_PATH):
            subprocess.run(["rm", "-rf", VENV_PATH], check=True)
        subprocess.run([sys.executable, "-m", "venv", VENV_PATH], check=True)
    else:
        print("Existing Python venv is recent.")

def ensure_gitignore_has_entries(entries):
    if os.path.exists(GITIGNORE_PATH):
        with open(GITIGNORE_PATH, "r") as f:
            lines = f.read().splitlines()
    else:
        lines = []

    updated = False
    with open(GITIGNORE_PATH, "a") as f:
        for entry in entries:
            if entry not in lines:
                print(f"Adding '{entry}' to .gitignore")
                f.write(f"{entry}\n")
                updated = True
    if not updated:
        print(".gitignore already contains necessary entries.")

def ensure_output_dir():
    if not os.path.exists(OUTPUT_PATH):
        print(f"Creating output directory: {OUTPUT_PATH}")
        os.makedirs(OUTPUT_PATH, exist_ok=True)

def read_clean_lines(path):
    with open(path, "r") as f:
        lines = []
        for line in f:
            line = line.split("#")[0].strip()
            if line:
                lines.append(line)
        return lines

def run_whois_query(host, query_args):
    try:
        result = subprocess.run(["whois", "-h", host] + query_args, capture_output=True, text=True, timeout=30)
        return result.stdout
    except Exception as e:
        return f"Error querying {host} with args {query_args}: {str(e)}"

def fetch_mnt_objects(irrdbs, maintainers):
    for irr in irrdbs:
        for mnt in maintainers:
            out = run_whois_query(irr, ["-i", "mnt-by", mnt])
            fname = os.path.join(OUTPUT_PATH, f"{mnt}-{irr}.txt")
            with open(fname, "w") as f:
                f.write(out)

def fetch_he_filters(asns):
    for asn in asns:
        url = f"https://routing.he.net/index.php?cmd=display_filter&as={asn}&af=4&which=irr"
        try:
            result = subprocess.run(["curl", "-s", url], capture_output=True, text=True, timeout=30)
            lines = [line for line in result.stdout.splitlines() if line.startswith("ip prefix-list")]
            fname = os.path.join(OUTPUT_PATH, f"he-filter-as{asn}.txt")
            with open(fname, "w") as f:
                f.write("\n".join(lines) + "\n")
        except Exception as e:
            fname = os.path.join(OUTPUT_PATH, f"he-filter-as{asn}.txt")
            with open(fname, "w") as f:
                f.write(f"Error fetching HE filter for AS{asn}: {str(e)}\n")

def fetch_origin_routes(irrdbs, asns):
    for irr in irrdbs:
        for asn in asns:
            out = run_whois_query(irr, ["-i", "origin", f"AS{asn}"])
            lines = []
            for block in out.strip().split("\n\n"):
                route_line = ""
                for line in block.splitlines():
                    if line.startswith("route:") or line.startswith("route6:"):
                        route_line = line
                        break
                if route_line:
                    lines.append(block)
            lines.sort()
            fname = os.path.join(OUTPUT_PATH, f"origin-AS{asn}-{irr}.txt")
            with open(fname, "w") as f:
                f.write("\n\n".join(lines) + "\n")

def main():
    if "INSIDE_VENV" not in os.environ:
        create_or_refresh_venv()
        python_bin = os.path.join(VENV_PATH, "bin", "python")
        env = os.environ.copy()
        env["INSIDE_VENV"] = "1"
        subprocess.run([python_bin] + sys.argv, env=env)
        sys.exit(0)

    ensure_output_dir()
    ensure_gitignore_has_entries([OUTPUT_DIR, VENV_DIR])

    maintainers = read_clean_lines("maintainers.txt")
    irrdbs = read_clean_lines("registries.txt")
    asns = read_clean_lines("autnums-filters.txt")

    fetch_mnt_objects(irrdbs, maintainers)
    fetch_he_filters(asns)
    fetch_origin_routes(irrdbs, asns)

    print("IRR data collection complete.")

if __name__ == "__main__":
    main()
