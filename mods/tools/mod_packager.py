import os
import argparse
import subprocess
import yaml
import math
import threading
import time
import sys

print_lock = threading.Lock()

dir_path = os.path.dirname(os.path.realpath(__file__))
config = None
cur_dir = os.getcwd()

parser = argparse.ArgumentParser(description='Compile and create mods depending on packager config')
parser.add_argument('-d', '--directory', help='input directory path')
parser.add_argument('-o', '--output', help='output directory path')
parser.add_argument('-c', '--config', help='config file path')
parser.add_argument('-p', '--parallel', help='flag to enable parallel compilation and packaging', action='store_true')

args = parser.parse_args()

if not args.directory:
    print('The input must be specified')
    quit(1)

if args.directory:
    if not os.path.exists(args.directory):
        print('The input directory does not exist')
        quit(1)

if not args.config:
    print('The config must be specified')
    quit(1)

if not args.output:
    print('The output must be specified')
    quit(1)

out_path = os.path.relpath(args.output, start=cur_dir)
os.makedirs(out_path, exist_ok=True)

if not os.path.exists(out_path):
    print('The output path specified does not exist')
    quit(1)

in_path = os.path.relpath(args.directory, start=cur_dir)
os.makedirs(in_path, exist_ok=True)

if not os.path.exists(in_path):
    print('The input path specified does not exist')
    quit(1)

with open(args.config, "r") as stream:
    try:
        config = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        print(exc)

if not config:
    print('Config file is empty')
    quit(2)

os.makedirs("./packager-tmp/", exist_ok=True)

for f in os.listdir(args.output):
    if '!' not in f:
        os.remove(os.path.join(args.output, f))

config_items = config.items()
launch_parallel = args.parallel == True

tmp_compiled = {}
tmp_merging = {}
uncompiled_files = []
new_net_config_path = './new.network_config'

for mod, _ in config_items:
    tmp_compiled[mod] = os.path.join(os.path.relpath("./packager-tmp/compile/", start=cur_dir), mod) 
    tmp_merging[mod] = os.path.join(os.path.relpath("./packager-tmp/merging/", start=cur_dir), mod) 

    if os.path.exists(tmp_compiled[mod]):
        for f in os.listdir(tmp_compiled[mod]):
            os.remove(os.path.join(tmp_compiled[mod], f))
        os.rmdir(tmp_compiled[mod])
    os.makedirs(tmp_compiled[mod], exist_ok=True)

    if os.path.exists(tmp_merging[mod]):
        for f in os.listdir(tmp_merging[mod]):
            os.remove(os.path.join(tmp_merging[mod], f))
        os.rmdir(tmp_merging[mod])
    os.makedirs(tmp_merging[mod], exist_ok=True)

def compile_file(in_path, out_path):
    subprocess.run(["python", dir_path + "/lua2bitsquid.py", "-f", in_path, "-o", out_path])

def run_mod_packaging(mod, files):
    comp_threads = []

    for file in files:
        if launch_parallel:
            thread = threading.Thread(target=compile_file, args=(args.directory + '/' + mod + '/' + file, tmp_compiled[mod] + '/' + file))
            comp_threads.append(thread)
            thread.start()
        else:
            compile_file(args.directory + '/' + mod + '/' + file, tmp_compiled[mod] + '/' + file)

    for thread in comp_threads:
        thread.join()

    for f in os.listdir(tmp_merging[mod]):
        os.remove(os.path.join(tmp_merging[mod], f))

    for file in files:
        compiled_path =  tmp_compiled[mod] + '/' + file
        if os.path.isfile(compiled_path):
            subprocess.run(['cp', tmp_compiled[mod] + '/' + file, tmp_merging[mod] + '/' + file])
        else:
            uncompiled_files.append((mod, file))

    if mod == "9e13b2414b41b842" and os.path.isfile(new_net_config_path):
        print_lock.acquire()
        subprocess.run(["echo", "adding new network config ..."])
        print_lock.release()
        subprocess.run(['cp', new_net_config_path, tmp_merging[mod] + '/000b2f08fe66e395c0.network_config'])

    print_lock.acquire()
    subprocess.run(["echo", "packaging mod [" + mod + "] ..."])
    print_lock.release()

    new_lua_files = [os.path.join(tmp_compiled[mod], f) for f in os.listdir(tmp_compiled[mod]) if os.path.isfile(os.path.join(tmp_compiled[mod], f))]
    subprocess.run(["tools/bubble/bubble.exe", "R", "./m2-data/" + mod, out_path + "/" + mod, *new_lua_files], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)

threads = []

for mod, files in config_items:
    if not launch_parallel:
        run_mod_packaging(mod, files)
    else:
        thread = threading.Thread(target=run_mod_packaging, args=(mod, files))
        threads.append(thread)
        thread.start()

for thread in threads:
    thread.join()

print("\r")
sys.stdout.flush()
time.sleep(0.25)

final_msg = ""
if len(uncompiled_files) > 0:
    final_msg += "WARNING: following required code files have failed to compile:\n"
    for mod, file in uncompiled_files:
        final_msg += "    " + str(mod) + "/" + str(file) + "\n"
else:
    final_msg += "All required code files have been successfully compiled\n"

final_msg = final_msg[:-1]

subprocess.run(["echo", final_msg])