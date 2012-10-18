<!--
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
# References

## Puppet Configuration

Printing the module path

Command: `puppet apply --configprint modulepath`

## Puppet Kick

puppet kick --host **host** --ping

## Puppet CA

List Certs

Command: `puppetca --list --all`

Revoke a Cert

Command: `puppetca revoke ` **host**

Sign a Cert

Command: `puppetca sign ` **host**

Clean all certs

Command: `puppetca --clean --all`

Re-exchange keys between an agent and a master

Command: `puppetd -tv --server=`**hmc master**

## Puppet lock file

rm /var/lib/puppet/state/puppetdlock

## Facter

Listing the facts about the machine on which puppet will perform the application of the manifest.  Each of these commands can be used by referencing them with ${variableName} from within a manifest.

Command: `facter`

Output:

* architecture
* augeasversion
* boardmanufacturer
* boardproductname
* boardserialnumber
* domain
* facterversion
* fqdn
* hardwareisa
* hardwaremodel
* hostname
* id
* interfaces
* ipaddress
* ipaddress_eth0
* ipaddress_lo
* is_virtual
* kernel
* kernelmajversion
* kernelrelease
* kernelversion
* lsbdistcodename
* lsbdistdescription
* lsbdistid
* lsbdistrelease
* lsbmajdistrelease
* lsbrelease
* macaddress
* macaddress_eth0
* manufacturer
* memoryfree
* memorysize
* memorytotal
* netmask
* netmask_eth0
* netmask_lo
* network_eth0
* network_lo
* operatingsystem
* operatingsystemrelease
* osfamily
* path
* physicalprocessorcount
* processor0
* processorcount
* productname
* ps
* puppetversion
* rubysitedirw
* rubyversion
* selinux
* serialnumber
* sshdsakey
* sshrsakey
* swapfree
* swapsize
* timezone
* type
* uniqueid
* uptime
* uptime_days
* uptime_hours
* uptime_seconds
* virtual

## Puppet References

[Puppet SSL Explained](http://www.masterzen.fr/2010/11/14/puppet-ssl-explained/)