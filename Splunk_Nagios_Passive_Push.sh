#!/bin/bash

#### Sample csv file
# Size, critical, alarm


### Set variables
SPLUNKSERVER=some_local_splunk_server
WWW=http://splunk.analytics.myowndomain.com
NSCABIN=/opt/SP/apps/nsca-2.7.2
NSCACFG=$NSCABIN/sample-config
NSCAHOST=bc-nagios06.prd.de1.sp.myowndomain.com
NSCAPORT=9191
HOST=`echo $5|awk -F'[' '{print $2}'|awk -F']' '{print $1}'|awk '{print $1}'|tr A-Z a-z`
EVENTS=$1
URL=$WWW/`echo $6|cut -c31-200`
NSCA_CODE=0

### New variables
IFS=,
myfile=$8
index=0

### Send to Nagios
nagios_notify () {
${NSCABIN}/send_nsca -H $NSCAHOST -p $NSCAPORT -d "," -c $NSCACFG/send_nsca.cfg <<EOF
$HOST,$NSCA_SERVICE_NAME,$NSCA_CODE,$NSCA_MSG
EOF
}

NSCA_SERVICE_NAME=$ORIG_NSCA_SERVICE_NAME

### Return Nagios UNKNOWN state where file with results is missing
[ ! -f $myfile ] && { NSCA_MSG="Unable to get search results from Splunk - $myfile file not found"; NSCA_CODE=3; }

if [ $NSCA_CODE -eq 3 ]; then
    nagios_notify
    exit $NAGIOS_CODE
fi

## Let's check local results file from Splunk
/bin/gunzip < $myfile | while read col1 col2 col3
do
   if [ $index -eq 0 ]; then
       size=$col1
   else
       if [ $col1 -gt 500 ]; then
           NSCA_CODE=$col3
           NSCA_MSG="High CDN downloads from Updates $col1GB downloads in last 1 hour (critical_threshold=500GB ok_threshold < 500GB, Last Hour downloads $col1GB)"
           NSCA_SERVICE_NAME=My-Own-Website-Android-High_CDN_Downloads_From_Updates
           nagios_notify
       else
           NSCA_MSG="$col1GB downloads is okay until its less than 500GB"
           NSCA_CODE=$col3
           NSCA_SERVICE_NAME=My-Own-Website-Android-High_CDN_Downloads_From_Updates
           nagios_notify
       fi

       NSCA_SERVICE_NAME=My-Own-Website-Android-High_CDN_Downloads_From_Updates

   fi

   index=$(($index+1))
done