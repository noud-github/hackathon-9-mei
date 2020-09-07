#!/usr/bin/python
import sys
f = open("/tmp/log.txt","a+")
f.write("---------------------------\n")
for arg in sys.argv:
	f.write(arg)
	f.write("\n")
	
if len(sys.argv)> 1:
	if sys.argv[1] == 'co':
		for arg in sys.argv:
			if arg =='--username=Yoast':
				# tag check needs to fail
				sys.exit(1)
			if arg =='--version':
				print('Mockup version 1.1')
        
sys.exit(0)
f.close()

