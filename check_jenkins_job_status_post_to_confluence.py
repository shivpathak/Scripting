#!/usr/bin/env python
import urllib, urllib2, json, requests, base64

baseurl='https://ACTUAL_JENKINS_URL/job/'
jobname=[LIST_OF_JOBS_NAME]
suffix='/lastBuild/api/json'
base64auth='BASE64_ENC_USER_PASS'
b64auth='BASE64_ENC_USER_PASS'
confluence='https://ACTUAL_CONFLUENCE_URL/rest/api/content/131923439'

def getCurVer():
 url=urllib2.Request(confluence)
 url.add_header("Authorization", "Basic %s" % b64auth)
 response=urllib2.urlopen(url)
 output=json.load(response)
 return output['version']['number']

filename='dev.out'
file=open(filename, 'rw+')
file.truncate()

conf_header="""
{"id": "131923439","type": "page","title": "ACTUAL_PAGE_NAME","space": {"key": "ISHS"},"body": {"storage": { "value": "<div class=\\"table-wrap\\"><table class=\\"confluenceTable\\"><tbody><tr><th class=\\"confluenceTh\\">Build No<\/th><th class=\\"confluenceTh\\">Display Name<\/th><th class=\\"confluenceTh\\">Branch<\/th><th class=\\"confluenceTh\\">Commit<\/th><th class=\\"confluenceTh\\">Console<\/th><th class=\\"confluenceTh\\">Status<\/th><\/tr>"""

file.writelines(conf_header)

def getresults(jobname):
 for name in jobname:
   print baseurl+name+suffix
   url=urllib2.Request(baseurl+name+suffix)
   url.add_header("Authorization", "Basic %s" % base64auth)
   response=urllib2.urlopen(url)
   data=json.load(response)
   for i in data['actions']:
     if 'lastBuiltRevision' in i:
       commit=i['lastBuiltRevision']['SHA1']
       branch=i['lastBuiltRevision']['branch'][0]['name']
   result=data['result']
   build_number=data['number']
   display_name=data['displayName']
   console=baseurl+'/'+str(name)+'/'+str(build_number)+'/'+'console'
   #print build_number, display_name, branch, commit, result, console
   global C
   if result == 'FAILURE':
    C='\\"red\\"'
   elif result == 'SUCCESS':
    C='\\"green\\"'
   conf_values="""<tr><td class=\\"confluenceTh\\">"""+str(build_number)+"""<\/td><td class=\\"confluenceTh\\">"""+str(display_name)+"""<\/td><td class=\\"confluenceTh\\">"""+str(branch)+"""<\/td><td class=\\"confluenceTh\\">"""+str(commit)+"""<\/td><td class=\\"confluenceTh\\">"""+str(console)+"""<\/td><td bgcolor="""+str(C)+""" class=\\"confluenceTh\\">"""+str(result)+"""<\/td></tr>"""
 #  print conf_values
   file.writelines(conf_values)
  
 footer="""<\/tbody><\/table><\/div>\", """
 file.writelines(footer)
 ver=getCurVer()
 newver=ver+1
 final_footer=""""representation": "storage" }}, "version": { "number": """+str(newver)+""" }}"""
 file.writelines(final_footer)
 file.close()
getresults(jobname)
