from pathlib import Path
import os
import argparse
import subprocess
import threading
import queue
import pprint

parser = argparse.ArgumentParser(description='Apply diff file tree as a patch to sources.')
parser.add_argument('-d', '--diff', help='path to directory containing diff file tree')
parser.add_argument('-t', '--target', help='path to a directory with sources')

args = parser.parse_args()

if not args.diff:
    print('The path to directory containing diff file tree must be specified')
    quit(1)

if args.diff:
    if not os.path.exists(args.diff):
        print('The directory containing diff file tree does not exist')
        quit(1)

if not args.target:
    print('The the path to directory with sources must be specified')
    quit(1)

if args.target:
    if not os.path.exists(args.target):
        print('The directory with sources does not exist')
        quit(1)

def build_diff_file_dict(folder_path):
    root = Path(folder_path)
    return {str(file.relative_to(root)): str(file.resolve()) for file in root.rglob('*') if file.is_file()}


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

def build_src_file_dict(folder_path):
    root = Path(folder_path)
    file_dict = {str(file.relative_to(root)): str(file.resolve()) for file in root.rglob('*') if file.is_file()}
    name_dict = {}

    for key, value in list(file_dict.items()):
        orig_name = get_orig_file_name(value)

        if orig_name:
            if orig_name in name_dict:
                name_dict[orig_name].append(value)
            else:
                name_dict[orig_name] = [value]
        else:
            print("[warning] failed to find chunkname for :: " + str(key))

    del file_dict

    return name_dict

diff_f_dict = build_diff_file_dict(args.diff)
src_f_dict = build_src_file_dict(args.target)

missing_keys = diff_f_dict.keys() - src_f_dict.keys()

if not missing_keys:
    print("found all necessary files, proceeding ...")
else:
    print("could not find necessary files :: ")

    for key in missing_keys:
        print("    " + key)

    quit(2)

def apply_patch_with_path_redirect(patch_path, target_path):
    patch_content = None
    cur_dir = os.getcwd()
    rel_patch_path = os.path.relpath(patch_path, start=cur_dir)
    rel_target_path = os.path.relpath(target_path, start=cur_dir)

    with open(rel_patch_path, 'rb') as f:
        patch_content = f.read().decode('utf-8')

    modified_patch_content = ""
    for line in patch_content.splitlines():
        if line.startswith('--- a/'):
            modified_patch_content += f"--- a/{rel_target_path}\n"
        elif line.startswith('+++ b/'):
            modified_patch_content += f"+++ b/{rel_target_path}\n"
        else:
            modified_patch_content += f"{line}\n"


    print(f"patching {rel_target_path}\n    with {rel_patch_path} ...")

    try:
        process = subprocess.run(
            ["git", "-c", "core.eol=lf", "-c", "core.autocrlf=false", "apply", "--ignore-whitespace", "--recount", "-p1", "--unidiff-zero", "-"],
            input=modified_patch_content,
            check=True,
            capture_output=True,
            text=True,
            encoding='utf-8'
        )
    except subprocess.CalledProcessError as e:
       print(f"        [err] patching failed for {rel_patch_path} :: {e.stdout}\n{e.stderr}\n")

def apply_patches(diff_dict, source_dict):
    for file_name, source_paths in source_dict.items():
        if file_name in diff_dict:
            patch_path = diff_dict[file_name]

            for source_path in source_paths:
                apply_patch_with_path_redirect(patch_path, source_path)

apply_patches(diff_f_dict, src_f_dict)