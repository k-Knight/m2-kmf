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

ljd_dir = os.path.split(os.path.realpath(__file__))[0] + '/ljd'
task_queue = queue.Queue()

def worker_thread():
    while True:
        try:
            in_file, out_dir, out_file = task_queue.get(timeout=2)
        except queue.Empty:
            return
        decompile_file(in_file, out_dir, out_file)
        task_queue.task_done()

def decompile_file(in_file, out_dir, out_file):
    folder_path = os.path.dirname(out_file)
    os.makedirs(folder_path, exist_ok=True)
    tmp_file = out_file + '.tmp'
    if os.path.exists(out_file):
        os.remove(out_file)

    file = open(in_file, 'rb')
    data = file.read()
    file.close()

    data = data[8:] # remove bitsquid header

    file = open(tmp_file, 'wb')
    file.write(data)
    file.close()

    if subprocess.run(['luajit-decompiler-v2.exe', tmp_file, '-o', out_dir, '-s', '-f'], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL).returncode != 0:
        if os.path.exists(out_file):
            os.remove(out_file)
        print('WARNING :: failed to decompile file [' + in_file + ']')
    else:
        if os.path.exists(out_file + '.lua'):
            os.rename(out_file + '.lua', os.path.dirname(out_file) + '/00' +  os.path.basename(out_file))
    os.remove(tmp_file)

if out_type == 1:
    in_path = os.path.abspath(args.file)
    os.chdir(ljd_dir)

    decompile_file(in_path, out_path)

elif out_type == 2:
    in_path = os.path.abspath(args.directory)
    os.chdir(ljd_dir)

    list_of_files = []
    for root, dirs, files in os.walk(in_path):
        for file in files:
            _, extension = os.path.splitext(file)
            if extension == '.lua':
                list_of_files.append(os.path.join(root, file))

    for i in range(0, len(list_of_files)):
        path = out_path + list_of_files[i].replace(in_path, '')
        task_queue.put_nowait( (list_of_files[i], os.path.dirname(path), path) )

    for _ in range(args.threads):
        threading.Thread(target=worker_thread).start()

    task_queue.join()