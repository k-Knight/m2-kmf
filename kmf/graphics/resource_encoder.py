import io
import os
import re

var_names = []
index = []

class index_entry:
    def __init__(self):
        self.name = ""
        self.path = ""
        self.size = 0

def dirFileSearch(path):
   fileCount, fileStructure = 0, []

   for root, _, filenames in os.walk(path):
      list(map(lambda fileName: fileStructure.append(fileName), list(map(lambda fileName: root + '\\' + fileName, filenames))))
      fileCount += len(filenames)

   return fileStructure, fileCount

def dirRecursiveDelete(path):
   if os.path.exists(path):
      for root, dirs, files in os.walk(path, topdown=False):
         for name in files:
            os.remove(os.path.join(root, name))
         for name in dirs:
            os.rmdir(os.path.join(root, name))

      os.rmdir(path)

def normalizeVariableName(name):
   res = re.sub(r'[^a-zA-Z\d]', '_', name)
   if res[0].isnumeric():
      res = '_' + res

   return res

def fileToBytearray(filePath):
   global var_names
   global index

   entry = index_entry()
   varName = normalizeVariableName(filePath)
   var_names.append(varName)
   entry.name = varName
   entry.path = filePath
   size = 0

   fileString = f'const uint8_t {varName}[] = {{\n'
   with io.open(filePath, mode='rb') as file:
      while (True):
         byteArr = file.read(20)
         if len(byteArr) < 1:
            break
         size += len(byteArr)
         hexString = '    '
         for byte in byteArr:
            hexString += '0x{0:02X}, '.format(byte)
         fileString += hexString + '\n'

   entry.size = size
   index.append(entry)
   fileString = fileString[: -3] + '\n};\n'
   fileString += f'size_t {varName}_len = sizeof({varName});\n'
   return fileString

dirRecursiveDelete('mem_resources')
os.mkdir('mem_resources')

fileStructure, fileCount = dirFileSearch('resources')
with io.open('mem_resources/resources.cpp', mode='w') as output_file:
   output_file.write("#include \"resources.hpp\"\n\n")
   for file in fileStructure:
      output_file.write(fileToBytearray(file))
      output_file.write('\n')

with io.open('mem_resources/resources.hpp', mode='w') as output_file:
   output_file.write("#include <stdint.h>\n\n")
   for varName in var_names:
      output_file.write("extern const uint8_t ")
      output_file.write(varName)
      output_file.write('[];\n')
      output_file.write("extern size_t ")
      output_file.write(varName)
      output_file.write('_len;\n\n')

total_size = 0
for entry in index:
   print(entry.name + "   " + str(entry.size))
   total_size += entry.size

print("\ndata total size is: " + str(total_size) + " - " + "0x{:01X}".format(total_size))
bin_index = bytes()

for entry in index:
   bin_index += bytes(entry.name, 'utf-8')
   bin_index += bytes('\0', 'utf-8')
   bin_index += entry.size.to_bytes(4, 'little')

bin_index = (len(bin_index) + 4).to_bytes(4, 'little') + bin_index

with io.open('mem_resources/data.ifa', mode='wb') as output_file:
   output_file.write(bin_index)
   for entry in index:
      with io.open(entry.path, mode='rb') as file:
         while (True):
            byteArr = file.read(512)

            if len(byteArr) < 1:
               break

            output_file.write(byteArr)