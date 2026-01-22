import argparse
import subprocess
import os
import sys

parser = argparse.ArgumentParser(description='Unpack bitsquid packed data')
parser.add_argument('-i', '--input', help='input directory path')
parser.add_argument('-o', '--output', help='output directory path')

args = parser.parse_args()

if not os.path.exists(args.input):
    print('Input file specified does not exist')
    quit(1)


if not os.path.exists(args.output) or not os.path.isdir(args.output):
    os.makedirs(args.output)

list_of_files = []
for root, dirs, files in os.walk(args.input):
    for file in files:
        _, extension = os.path.splitext(file)
        if extension != '.ini':
            list_of_files.append(os.path.join(root, file))

base_path, _ = os.path.split(args.output)
script_directory = os.path.dirname(os.path.abspath(sys.argv[0]))
bubble_path = script_directory + "/bubble_new/bubble.exe"

for file in list_of_files:
    _, file_name = os.path.split(file)
    out_dir = base_path + "/" + file_name

    if not os.path.exists(out_dir) or not os.path.isdir(out_dir):
        os.makedirs(out_dir)

    subprocess.run([bubble_path, 'U', file, out_dir])
