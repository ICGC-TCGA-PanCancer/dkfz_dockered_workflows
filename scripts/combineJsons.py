#!/usr/bin/python


#convert simple tab seperated file wit header 
import argparse
import sys
import json
from python_modules import Tabfile

parser=argparse.ArgumentParser(description='Convert tab seperated CNV calls to vcf file' )
parser.add_argument('--cnv',	  	'-c', type=file, help='cnv json')
parser.add_argument('--gcBias',		'-g', type=file, help= 'gc-bias json')
parser.add_argument('--snv_mnv', 	'-s', type=file, help='snv json')
parser.add_argument('--indel', 	  	'-i', type=file, help='indel Json')
parser.add_argument('--tumorID',   	'-t', type=str, help='Tumor aliquot ID')
parser.add_argument('--out',   		'-o', type=str, help='Tumor aliquot ID')

parser.add_argument
args = parser.parse_args()



if __name__=='__main__':

	if not args.cnv or not args.gcBias or not args.snv_mnv or not args.indel or not args.tumorID:
		sys.stderr.write("ERROR: Please specify cnv, snv, indel and qcBias Json file and make sure that the tumor aliquot ID is given. For more information, use -h.\n\n\n")
		sys.exit(2)

	if not args.out:
		out=sys.stdout
	else:
		try:
			out=open(args.out, 'w')
		except IOError as (errno, strerr ):
			sys.stderr.write("WARNING: Specified outputfile cannot be written. Please check given path.\n")
			sys.exit("IOError %i:%s\n" % (errno, strerr))


	try:
		cnv 	= json.loads(args.cnv.read())
		snv 	= json.loads(args.snv_mnv.read())
		indel 	= json.loads(args.indel.read())
		gcBias 	= json.loads(args.gcBias.read())

	except IOError as (errno, strerr ):
		sys.exit("IOError %i:%s\n" % (errno, strerr))

	jsonID = {}
	jsonID['cnv'] 	  =  cnv["cnv"] 
	jsonID['snv_mnv'] =  snv["snv_mnv"]
	jsonID['indel']   =  indel["indel"]
	jsonID['gc_bias'] =  gcBias["gc_bias"]
	jsonID = {args.tumorID : jsonID }
	jsonMain = { "qc_metrics" : jsonID }
	out.write( json.dumps(jsonMain, indent=2, separators=(",",":")) )

