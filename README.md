## default.env

This file contains the main properties used by the docker-compose.yml.
Its content is copied as is in .env during the execution of the script run-jmeter-in-docker.
Then, .env is completed by a script generated property REMOTE_WORKERS_TRIGGERED based on how many workers you want to launch.

- Properties starting with ULIMITS and SYSCTLS are tuning properties for the jmeter workers
- JMETER_VERSION must contain the version of the dockerized jmeter
- CONTROLLER_EXTRA_JMETER_PROPERTIES can be used to add jmeter properties other than the fixed ones which are:
	- -Jserver.rmi.ssl.disable=true 
	- -Jclient.tries=3 
	- -n 
	- -f
	- -t jmx/test.jmx 
	- -l results/result.jtl 
	- -X 
	- -R ${REMOTE_WORKERS_TRIGGERED}
	- -e
	- -o report

ROOT_DIR must contain the path to the root directory of the following structure

.
|-- jmx/
|---- test.jmx
|-- license/
|---- ubik-streaming-plugin.license
|-- properties/
|---- user-controller.properties
|---- user-worker.properties
|---- saveservice-controller.properties
|---- saveservice-worker.properties
|-- logs/
|---- controller/
|---- workers/
|-- results/
|-- report/

with:
- test.jmx, the test plan to execute
- ubik-streaming-plugin.license, the license file for the ubik plugin
- user-controller.properties, the file overriding user.properties on the controller
- user-worker.properties, the file overriding user.properties on every worker
- saveservice-controller.properties, the file overriding saveservice.properties on the controller
- saveservice-worker.properties, the file overriding saveservice.properties on every worker
- logs/: The folder that will contain log files after the execution
	- the garbage collector log file of the controller
    - in controller/ the jmeter.log of the controller jmeter
    - in workers/ the jmeter-worker-<WORKER_NB>.log of each worker
- results/: The folder that will contain the result.jtl file after the execution
- report/: The folder that will contain the execution report after the execution


To ensure that the docker can erase and rewrite result files and log files, ensure that it can write in logs/, results/ and report/ and their content by using the following command:
`sudo chmod o+w -R logs/ results/ report/`

Note: The script file generateFolderTree.sh can be used on UNIX systems to generate the correct folder structure and permissions. (See below)


## docker-compose-base.yml

This file contains the base of docker-compose.yml.
It defines the jmeter controller service and a template for jmeter worker service.
Its content is copied as is in docker-compose.yml during the execution  of the script run-jmeter-in-docker.
Then, docker-compose.yml is completed by script generated informations:
- The controller service declaration is completed with a depends_on node to include a dependance with the workers
- The expected number of worker service declarations is added

## run-jmeter-in-docker .sh

This is the main executable of the project.
When running this script, you will be ask how many workers you want to run between 1 and 14 included by default. If you want to change the max value you can execute ```export MAX_WORKER_NB=value```. Based on your answer the script will 
1. Generate a property value for the -R option of your jmeter controller, so that every wanted worker is remotely started by the controller command
2. Generate a depends_on attribute in the service declaration of the jmeter-controller in docker-compose.yml to ensure that workers are starting before the controller
3. Generate a service description for each worker in docker-compose.yml
4. Run docker-compose up. Controller and worker execute ```set JVM_ARGS=${JVM_ARGS_CONTROLLER}``` and ```set JVM_ARGS=${JVM_ARGS_WORKER}``` respectively before running jmeter. You can set those in default.env.
5. Cleanup files docker-compose.yml, .env, and a temporary yml file used to store the workers services after the end of the test


## generateFolderTree.sh

Before the first run of run-jmeter-in-docker, you can use this script on UNIX systems to create the required data folder.
1. Run this script
2. Specify the location where you want the 6 data folders (jmx, license, logs, properties, report, results) to be generated
3. Update default.env ROOT_PATH property
4. Move the required files in the correct folder (test plan, license file, property files)
5. Run run-jmeter-in-docker script
