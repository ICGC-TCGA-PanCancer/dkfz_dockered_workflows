#!/usr/bin/python

import sys
import os

try:	
		pid = sys.argv[1]
		path = sys.argv[2]		
		ppFile = open('%s/%s_ploidy_purity_2D.txt'% (path, pid) ) 
		distances = []
		ploidies = []
		entries =[]
		for line in ppFile:
			#colnames ppFile: ploidy ploidy_factor purity distance
			if line.startswith("ploidy"):
				continue	
			fields = line.rstrip("\n").split("\t")
			distances.append(float(fields[3]) )
			ploidies.append(float(fields[1]) )
			entries.append(fields)
		contin=1
except:
		print "FILE for %s does not exist"% pid
		contin = 0

if contin==1:
		m = min( [ abs( j-2.0 ) for j in ploidies ] )
		index = [i for i,j in enumerate(ploidies) if abs(j-2.0)==m ]

		print "%s/%s.%s_%s.cnv.vcf.gz"% ( path, pid, entries[index[0]][1], entries[index[0]][2] )

