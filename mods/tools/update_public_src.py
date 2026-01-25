import os
import argparse
import subprocess
import yaml
import math
import threading
import time
import sys
import shutil
from pathlib import Path

print_lock = threading.Lock()

dir_path = os.path.dirname(os.path.realpath(__file__))
config = None

parser = argparse.ArgumentParser(description='Compile and create mods depending on packager config')
parser.add_argument('-d', '--directory', help='input directory path')
parser.add_argument('-s', '--source', help='source directory path')
parser.add_argument('-o', '--output', help='output directory path')
parser.add_argument('-c', '--config', help='config file path')
args = parser.parse_args()

if not args.directory:
    print('The input must be specified')
    quit(1)

if args.directory:
    if not os.path.exists(args.directory):
        print('The input directory does not exist')
        quit(1)

if not args.source:
    print('The source must be specified')
    quit(1)

if args.source:
    if not os.path.exists(args.source):
        print('The source directory does not exist')
        quit(1)

if not args.config:
    print('The config must be specified')
    quit(1)

if not args.output:
    print('The output must be specified')
    quit(1)

src_path = os.path.abspath(args.source) + "/"
mod_path = os.path.abspath(args.directory) + "/"
out_path = os.path.abspath(args.output) + "/"
os.makedirs(out_path, exist_ok=True)

if not os.path.exists(args.output):
    print('The output path specified does not exist')
    quit(1)

with open(args.config, "r") as stream:
    try:
        config = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        print(exc)

if not config:
    print('Config file is empty')
    quit(2)
for f in os.listdir(args.output):
    if '!' not in f:
        shutil.rmtree(os.path.join(args.output, f))

config_items = config.items()

def rename_diff_header(diff_str, new_src_path):
    lines = diff_str.splitlines()

    lines[0] = f"diff --git a/{new_src_path} b/{new_src_path}"
    lines[2] = f"--- a/{new_src_path}"
    lines[3] = f"+++ b/{new_src_path}"

    return "\n".join(lines)

def get_orig_file_name(file_path):
    line = None

    with open(file_path, 'r', encoding='utf-8') as file:
        for f_line in file:
            if f_line.strip():
                line = f_line
                break

    if line == None:
        return None

    start_index = line.find('@')
    if start_index != -1:
        return line[start_index + 1:].strip()

    return None

for mod, files in config_items:
    mod_mod_path = mod_path + mod + "/"
    src_mod_path = src_path + mod + "/"

    for file in files:
        modified_file_path = mod_mod_path + file
        source_file_path = src_mod_path + file
        rel_src_path = os.path.relpath(source_file_path, start=src_path)
        rel_mod_path = os.path.relpath(modified_file_path, start=mod_path)

        print("diffing :: " + rel_src_path)
        orig_name = get_orig_file_name(source_file_path)
        if orig_name == None:
            print("Failed to get original name for :: " + rel_src_path)
            continue

        diff_file_path = out_path + orig_name
        path = Path(diff_file_path)

        diff = subprocess.run(["git", "-c", "core.eol=lf", "-c", "core.autocrlf=false", "diff", "--no-index", source_file_path, modified_file_path], capture_output=True, text=True, encoding='utf-8').stdout
        try:
            diff = rename_diff_header(diff, orig_name) + "\n"
        except:
            print("  failed to rename diff ::")
            print(diff)
            continue

        if os.path.exists(diff_file_path):
            print("OVERWRITING THE FILE !!! ::\n    " + rel_mod_path)

        path.parent.mkdir(parents=True, exist_ok=True)
        with open(diff_file_path, "wb") as f:
            f.write(diff.encode("utf-8"))

