#!/usr/bin/python

import csv
import sys
import os

print "Reading Ambari-Generated file: ", sys.argv[1]
input = open(sys.argv[1], 'rb')
try: 
	reader = csv.reader(input)
	for row in reader:
		if len(row)!=0:
			host = row[0]
			component = row[1]
			principal = row[2]
			filename = row[3]
			target = row[4]
			user = row[5]
			group = row[6]
			permission = row[7]
			
			print host
			print component
			print principal
			print filename
			print target
			print user
			print group
			print permission

			#Create keytab directory on host
			command = "ssh " + host + " \"mkdir -p /etc/security/keytabs\""
			print command
			os.system(command)
			
			#Create principal if required
			command = "kadmin.local -q \"addprinc -randkey " + principal + "\""
			print command
			os.system(command)
			
			#Create keytab file for principal 
			command = "kadmin.local -q \"xst -keytab " + filename + " -norandkey " + principal + "\""
			print command
			os.system(command)

			#Copy keytab to appropriate host
			command = "scp " + filename + " " + host + ":" + target
			print command
			os.system(command)

			#Take appropriate ownership on the keytab
			command = "ssh " + host + " \"chown " + user + ":" + group + " /etc/security/keytabs/" + filename + "\""
			print command
			os.system(command)
			
			#Set approripate permissions on the keytab
			command = "ssh " + host + " \"chmod " + permission + " /etc/security/keytabs/" + filename + "\""
			print command
			os.system(command)
			
	print ("Finished Iterating")		
	
finally:
	input.close()

