
##### [MAIN REPOSITORY](https://github.com/wintersys-projects/adt-build-machine-scripts)

##### This repository is the code which implements the autoscaling functions of the Agile Deployment Toolkit

The autoscaler can be configured to spawn a predefined number of webservers which you can set using the ${BUILD_HOME}/helperscripts/AdjustScaling.sh script on your build machine. 

This isn't strictly autoscaling because how many websevers to scale out to is statically defined, so, this toolkit might not be the best solution for use cases that need to service sudden spikes in traffic.

The autoscalers are only buit and deployed when in "PRODUCTION" mode with development mode, no autoscalers are involved. 

If there are providers which have options for dynamic scaling it might be possible to build this solution out so that the provider's dynamic scaling is actionable this would make this solution more suitable for applications that experience sudden spikes. For now, this is a solution which is best suited, to, for example, social networks which have predictable usage profiles in a day in day out basis so that you can, for example, set your system to scale up its number of webservers in the early morning and scale them back down at night. Or if you have a predictable usage spike at midday, scale up at 11:30 by a few webservers and then scale back down at 1:30 and so on. 

The autoscaler probes the fleet of webservers that you have got running as a "health check" mechanism and if a webserver fails its healthcheck it will be shutdown and the scaling mechaism will detect that a new webserver needs to be spun up in order to satisfy the current scaling requirements. The health check consists of appplying a more and more restrictive set of tests to each webserver on each parse of the health check mechanism and if the webserver that is having its health checked passes all of the tests culminating in a call using curl to to check the HTTP status returned by the webserver, then, that webserver is considered alive and is allowed to live on. 

You can deploy multiple autoscalers and the reason for this in most cases is resilience. If you have 3 autoscalers running and you issue a scaling command to build 15 additional webservers on top of the 2 that you currently have running then, 5 webservers will be actioned by each autoscaler. If you only had one autoscaler running and you issued the same command then 15 webservers would be built by the one autoscaler. The autoscaling mechanism waits until all the webservers that it is expecting to build complete their build process and then it reboots itself to reinitialise the machine ready for the next autoscaling command. Once a machine is in a "scaling" state in other words, webservers are being built that the current machine is responsible for, no other scaling commands are accepted (from cron) until the current scaling cycle is considered complete. 



