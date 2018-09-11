#!/opt/SP/apps/python-2.7.12/bin/python
#Author: Shiv Pathak
#Ver: 1.0
#Date: 31-07-2017
#Description: Downloads compressed access log files from CDN for defined targets in yaml file.

import argparse as ap
import yaml as y
import sys,os,botocore,gzip,datetime,subprocess,time
from boto3 import client

def main():
	#os.environ["PATH"]
	#os.environ["LD_LIBRARY_PATH"]
	dt=datetime.datetime.today().strftime('%Y-%m-%d-%H:%M:%S')
	start_time = time.time()
	parser = ap.ArgumentParser()
	parser.add_argument("-c", "--config", help="Please provide input yaml", required="True") 
	args = parser.parse_args()
	if 'yaml' not in args.config:
		print "Missing input yaml file"

	stream = open(args.config, 'r')
	myconfig = y.load_all(stream)

        for section in myconfig:
                p=section['platforms']
                for i in p:
                        key="config_"+i
			if key not in section:
				print ""
				print "You are missing config for key section",key,"will exit now"
				quit()
                        KEY=section[key]['AWS_KEY']
                        SECRET=section[key]['AWS_SECRET']
                        BKT=section[key]['S3']['bucket']
                        TGT=section[key]['S3']['target']
			conn = client('s3',aws_access_key_id=KEY,aws_secret_access_key=SECRET,region_name='eu-central-1')
			dict=conn.list_objects(Bucket=BKT)
			
			if not os.path.exists(TGT):
				os.makedirs(TGT)

			print ""
			print "processing",key,"=> downloading in",TGT
			if 'Contents' not in dict:
				print "Nothing is there in s3://"+BKT
			else:
				os.chdir(TGT)
				if not os.path.exists('.tmp'):
					os.makedirs('.tmp')
				for f in dict['Contents']:
					print "Downloading",f['Key']
					k=f['Key']
					with open(k, 'wb') as data:
						conn.download_fileobj(BKT, k, data)
					print "Decompressing", k
					with gzip.open(k, 'r:gz') as gz_file:
						s = gz_file.read()
						s = s.split("\n",2)[2];
					d_file='.tmp'+'/'+k[:-3]
					with open(d_file, 'w') as f:
						f.write(s)
					f.close()
					subprocess.call(["rm", "-f", k])
					subprocess.call(["mv", d_file, "."])
					conn.delete_object(Bucket=BKT, Key=k)

	print ""
	print "processing finished at",dt
	print("%s seconds taken" % (time.time() - start_time))	

if __name__ == "__main__":
	main()
