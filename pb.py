#!/usr/bin/python3

import sys
import argparse

def eprint(*args, **kwargs):
        print(*args, file=sys.stderr, **kwargs)

parser = argparse.ArgumentParser(description = 'Main arguments')
parser.add_argument('--disk', action='store', dest='disk')
args = parser.parse_args()

eprint("DISK: "+args.disk)

class Backuper:
    def __init__(self):
        self.disk = args.disk


    def __create_temp_dir():
        pass

