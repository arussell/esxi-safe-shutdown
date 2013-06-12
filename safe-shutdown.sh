#!/bin/sh

### Copyright (c) 2013 Aaron B. Russell <aaron@unadopted.co.uk>
### All rights reserved.
### 
### Redistribution and use in source and binary forms, with or without
### modification, are permitted provided that the following conditions are met:
###     * Redistributions of source code must retain the above copyright
###       notice, this list of conditions and the following disclaimer.
###     * Redistributions in binary form must reproduce the above copyright
###       notice, this list of conditions and the following disclaimer in the
###       documentation and/or other materials provided with the distribution.
###     * Neither the name of the Aaron B. Russell, Rocket Dog Creative, nor the
###       names of its contributors may be used to endorse or promote products
###       derived from this software without specific prior written permission.
### 
### THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
### ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
### WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
### DISCLAIMED. IN NO EVENT SHALL AARON B. RUSSELL OR ROCKET DOG CREATIVE BE LIABLE FOR ANY
### DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
### (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
### LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
### ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
### (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
### SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

### Bug reports, improvement requests, etc all welcome at https://github.com/arussell/esxi-safe-shutdown
### Better yet, fork the project and send me a pull request!

### Inspired by http://thehelpfulhacker.net/2012/11/02/graceful-ups-shutdowns-for-your-esxi-server-with-centos/

### Remember: ESXi runs sh not bash, so don't do anything fancy that needs bash or it won't work

## Get a list of all VMs that do not inclue "ups" in the name and loop through them
vim-cmd vmsvc/getallvms --help | grep vmx | grep -v ups | awk '{print $1}' | grep -v - | while read vm; do
  # Get the current VM's name
  vmname=`vim-cmd vmsvc/get.summary $vm | grep "name =" | awk '{print $3}' | sed 's/[\",]//g;'`
  echo -ne "Shutting down $vmname"
  # Shutdown the VM
  vim-cmd vmsvc/power.shutdown $vm >/dev/null 2> /dev/null
  # Ensure machine shuts down so we don't kill the host before it's had a chance to finish shutting down
  while vim-cmd vmsvc/power.getstate $vm | tail -1 | grep 'on' >/dev/null ; do
    # If it's still on, come back and check again in 1 second
    echo -ne "."
    sleep 1
  done
  # It's shut down (or was already powered off)
  echo " done!"
  # Move onto the next VM, if any
done
# All VMs shutdown except the UPS VM, so shutdown host
echo "Shutting down ESXi host `hostname`..."
poweroff
