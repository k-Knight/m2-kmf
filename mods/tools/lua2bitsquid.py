import os
import argparse
import subprocess
import threading
import queue

parser = argparse.ArgumentParser(description='Convert lua file into bytecode for bitsquid')
parser.add_argument('-f', '--file', help='input file path')
parser.add_argument('-d', '--directory', help='input directory path')
parser.add_argument('-o', '--output', help='output file or directory')
parser.add_argument('-t', '--threads', help='set number of threads, default = 1', type=int)

args = parser.parse_args()

if not args.threads or args.threads < 1:
    args.threads = 1

if (args.file and args.directory):
    print('Only one of input methods can be specified.')
    quit(1)

out_type = 0
if args.file:
    out_type = 1
elif args.directory:
    out_type = 2

if out_type == 1 and args.file:
    if not os.path.exists(args.file):
        print('Input file specified does not exist')
        quit(1)

if out_type == 2 and args.directory:
    if not os.path.exists(args.directory):
        print('The input directory does not exist')
        quit(1)

if not args.output:
    print('The output must be specified')
    quit(1)

out_path = os.path.abspath(args.output)
if out_type == 1:
    folder_path = os.path.dirname(out_path)
    os.makedirs(folder_path, exist_ok=True)
else:
    os.makedirs(out_path, exist_ok=True)

if not os.path.exists(args.output) and out_type == 2:
    print('The path specified does not exist')
    quit(1)

luajit_dir = os.path.split(os.path.realpath(__file__))[0] + '/luajit'
task_queue = queue.Queue()

def worker_thread():
    while True:
        try:
            in_file, out_file = task_queue.get(timeout=2)
        except queue.Empty:
            return
        compile_file(in_file, out_file)
        task_queue.task_done()

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

def compile_file(in_file, out_file):
    folder_path = os.path.dirname(out_file)
    os.makedirs(folder_path, exist_ok=True)
    if os.path.exists(out_file):
        os.remove(out_file)

    orig_name = get_orig_file_name(in_file)
    cmd = None
    if orig_name:
        new_file_name = orig_name + "[m2-kmf]"
        new_module_name = "m2_kmf_" + orig_name.replace('/', '_')
        cmd = ['./luajit.exe', '-bg', '-n', new_module_name, '-F', new_file_name, in_file, out_file]
    else:
        cmd = ['./luajit.exe', '-bg', in_file, out_file]

    if subprocess.run(cmd).returncode != 0:
        if os.path.exists(out_file):
            os.remove(out_file)
        print('WARNING :: failed to compile file [' + in_file + ']')

    if os.path.exists(out_file):
        size = os.path.getsize(out_file)
        file = open(out_file, 'rb')
        data = file.read()
        file.close()

        os.remove(out_file)
        file = open(out_file, 'wb')
        file.write(size.to_bytes(4, byteorder='little', signed=False))
        file.write((2).to_bytes(4, byteorder='little', signed=False))
        file.write(data)
        file.close()

if out_type == 1:
    in_path = os.path.abspath(args.file)
    os.chdir(luajit_dir)

    compile_file(in_path, out_path)

elif out_type == 2:
    in_path = os.path.abspath(args.directory)
    os.chdir(luajit_dir)

    list_of_files = []
    for root, dirs, files in os.walk(in_path):
        for file in files:
            _, extension = os.path.splitext(file)
            if extension == '.lua':
                list_of_files.append(os.path.join(root, file))

    for i in range(0, len(list_of_files)):
        task_queue.put_nowait( (list_of_files[i],  out_path + '/' + list_of_files[i].replace(in_path, '')) )

    for _ in range(args.threads):
        threading.Thread(target=worker_thread).start()

    task_queue.join()