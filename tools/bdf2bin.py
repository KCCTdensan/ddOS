#!/usr/bin/env python3

import argparse
from sys import stderr

parser=argparse.ArgumentParser()
parser.add_argument("filein",metavar="hoge.bdf")
parser.add_argument("fileout",metavar="fuga.bin")
args=parser.parse_args()

def hexchar(c):
  if c=='A': return 0xa
  if c=='B': return 0xb
  if c=='C': return 0xc
  if c=='D': return 0xd
  if c=='E': return 0xe
  if c=='F': return 0xf
  return int(c)

fonts=[[]]*256
rows=[]
fbbx=[]
fsize=[0,0]
fmargin=[0,0]
i=0

with open(args.filein) as f:
  rows=f.read().split('\n')

while i<len(rows):
  l=rows[i]
  if l.startswith("FONTBOUNDINGBOX"):
    fbbx=list(map(int,l.split()[1:5]))
    fsize=fbbx[0:2]
    fmargin=[-fbbx[2],-fbbx[3]]
  #elif l.startswith(""):
  #  pass
  #  continue
  elif l.startswith("STARTCHAR"):
    break
  i+=1
if not fbbx:
  print("couldn't find FONTBOUNDINGBOX",file=stderr)
  exit(1)

while i<len(rows):
  l=rows[i]

  if l.startswith("STARTCHAR"):
    j=i+1
    char=0
    head=0
    headx=0
    heady=0
    skip=False
    font=[[0]*fsize[0] for _ in range(fsize[1])]
    size=[0,0]
    margin=[0,0]

    while True:
      l=rows[j]

      if l.startswith("ENCODING"):
        char=int(l.split()[1])
        if char>len(fonts)-1:
          skip=True
          break
      elif l.startswith("BBX"):
        bbx=list(map(int,l.split()[1:5]))
        size=bbx[0:2]
        margin=[-bbx[2],-bbx[3]]
      elif l.startswith("BITMAP"):
        j+=1
        break
      j+=1
    if skip:
      i+=2
      continue
    head=j
    headx=fmargin[0]-margin[0]
    heady=(fsize[1]-fmargin[1])-(size[1]-margin[1])
    while True:
      l=rows[j]
      fl=[]

      if l.startswith("ENDCHAR"):
        break
      for ci in range(min(len(l)*4,fsize[0]-headx)):
        font[j-head+heady][headx+ci]=hexchar(l[ci//4])>>(3-ci%4)&1
      j+=1
    fonts[char]=font
    i=j
  if l.startswith("ENDFONT"):
    break
  i+=1

with open(args.fileout,mode="wb") as f:
  f.write(bytes(fsize))
  for font in fonts:
    buf=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] # 16B per char
    c=0
    for row in font:
      for b in row:
        buf[c//8]|=b<<(7-c%8)
        c+=1
    f.write(bytes(buf))
