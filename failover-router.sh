#!/bin/bash

# Set Variables

# Remote Site (Internet)

Endpoint=8.8.8.8
# Set FailbackCheckIP as a static router (primary route) on server so it can detect when to fail back
FailbackCheckIP=4.2.2.2

# Site Specific (local site)

PrimaryGateway=<enter primary gateway address>
SecondaryGateway=<enter secondary gateway address>
CurrentGateway=$PrimaryGateway
Failover=0
interval=30
smtpserver=<enter smtp server>
toaddress=<enter to address>
fromaddress=<enter from address>

Foreverloop=1

# Loop Forever

while [ $Foreverloop -eq 1 ]; do

#Internet Check

#echo "Checking Internet ($InternetEndpoint)"
if [ $Failover -eq 0 ] ; then
   ping -c 5 $Endpoint &>/dev/null
   if [ $? -ne 0 ] ; then
      ping -c 30 $Endpoint &>/dev/null
      if [ $? -ne 0 ] ; then
         date
         echo "$Endpoint confirmed down - running final check"
         ping -c 60 $Endpoint &>/dev/null
         if [ $? -ne 0 ] ; then
            echo "$Endpoint is down! Initiating failover route change"
            if [ $CurrentGateway == $PrimaryGateway ] ; then
               route del default gw $PrimaryGateway
               route add default gw $SecondaryGateway
               CurrentGateway=$SecondaryGateway
               Routechange="Internet now via $SecondaryGateway"
               Failover=1
            fi
            route -n | grep default
            sendEmail -f $fromaddress -t $toaddress -u "Alert: Internet Failover Initiated" -m "Following change was made: $Routechange" -s $smtpserver
         fi
      fi
   fi
else
   #Internet Failback Check
   ping -c 10 $FailbackCheckIP &>/dev/null
   if [ $? -eq 0 ] ; then
      route del default gw $SecondaryGateway
      route add default gw $PrimaryGateway
      CurrentGateway=$PrimaryGateway
      Routechange="Internet now restored to primary via $PrimaryGateway"
      Failover=0
      echo "Primary connection restored - routing Internet via $PrimaryGateway again"
      route -n | grep default
      sendEmail -f $fromaddress -t $toaddress -u "Alert: Internet Failback Initiated" -m "Following change was made: $Routechange" -s $smtpserver
   fi
fi

sleep $interval

done
