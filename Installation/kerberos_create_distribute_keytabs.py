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
                        #command = "kadmin -p admin -kt admin.keytab -q \"addprinc -randkey " + principal + "\""
                        command = "ipa service-add " + principal
                        print command
                        os.system(command)

                        #If keytab file already exists, use it instead of generating a new one
                        if not os.path.isfile(filename):
                                #Create keytab file for principal
                                command = "kadmin -p admin -kt admin.keytab -q \"xst -keytab " + filename + " " + principal + "\""
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

                        #If the principal isn't host-specific, don't delete the keytab file
                        if principal.find("/") > -1:
                                #Delete local copy of generated keytab file
                                command = "rm -rf " + filename
                                print command
                                os.system(command)

        print ("Finished Iterating")

        #Delete all remaining keytabs
        command = "rm -rf *.keytab"
        print command
        os.system(command)

finally:
        input.close()
