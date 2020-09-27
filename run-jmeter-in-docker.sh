#! /bin/bash

# Initialization of properties and docker-compose 
# Creates .env file with same content as default.env
cat default.env > .env;
# Creates docker-compose.yml file with same content as docker-compose-base.yml file
cat docker-compose-base.yml > docker-compose.yml;
# Creates empty docker-compose-tmp-workers.yml temporary file
echo '' > docker-compose-tmp-workers.yml;

FOUR_SPACES='    '
EIGHT_SPACES="$FOUR_SPACES$FOUR_SPACES";
TWELVE_SPACES="$FOUR_SPACES$FOUR_SPACES$FOUR_SPACES";
LINE_SEPARATOR='_________________________________________';

PROPERTY_NAME='REMOTE_WORKERS_TRIGGERED=';
BASE_NAME='jmeter-worker';
SERVICE_ANCHOR='*worker-configuration';
DEPENDANCE='depends_on:';
COMMAND_NODE='command:'


WORKER_NB='0';
MIN_WORKER_NB='1';
MAX_WORKER_NB_DEFAULT='14';

if [ -z "$MAX_WORKER_NB" ]
then
      MAX_WORKER_NB=$MAX_WORKER_NB_DEFAULT
fi

while (("$WORKER_NB" < "$MIN_WORKER_NB")) || (("$WORKER_NB" > "$MAX_WORKER_NB")); do
    read -p "How many jmeter workers do you want to activate ? [$MIN_WORKER_NB-$MAX_WORKER_NB] " WORKER_NB;
done

echo -e "\n  Updating docker-compose.yml\n$LINE_SEPARATOR";
echo -e "$EIGHT_SPACES$DEPENDANCE" >> docker-compose.yml;
for i in `seq 1 $WORKER_NB`;
do
	WORKER_NAME="$BASE_NAME$i";
	PROPERTY_NAME="$PROPERTY_NAME$WORKER_NAME";
	if [ $i != $WORKER_NB ]
	then
		PROPERTY_NAME="$PROPERTY_NAME,";
	fi

	# Adds a dependance in controller service for this worker
	echo -e "$TWELVE_SPACES- \042$WORKER_NAME\042" >> docker-compose.yml;
	echo "Added a dependance in controller service for worker $WORKER_NAME";

	# Adds this worker service in temporary file docker-compose-tmp-workers.yml
	echo -e "$FOUR_SPACES$WORKER_NAME:\n$EIGHT_SPACES<< : $SERVICE_ANCHOR" >> docker-compose-tmp-workers.yml;
	ADD_JVM_ARGS='set JVM_ARGS=${JVM_ARGS_WORKER}'; # JVM_ARGS_WORKER is defined in default.env.
	# Default.env is evaluated when command docker-compose is executed. Which is not yet the case.
	# Hence, the single quotes not to evaluate JVM_ARGS_WORKER yet but only when the jmeter-worker command will be executed.
	DISPLAY_ARGS='echo ${JVM_ARGS_WORKER}';
	JMETER_COMMAND="jmeter -Jserver.rmi.ssl.disable=true --server -j logs/workers/jmeter-worker$i.log";

	COMMAND="$EIGHT_SPACES$COMMAND_NODE\n";
	COMMAND+="$TWELVE_SPACES- sh\n";
	COMMAND+="$TWELVE_SPACES- -c\n";
	COMMAND+="$TWELVE_SPACES- |\n";
	COMMAND+="$TWELVE_SPACES  $DISPLAY_ARGS\n";
	COMMAND+="$TWELVE_SPACES  $ADD_JVM_ARGS\n";
	COMMAND+="$TWELVE_SPACES  $JMETER_COMMAND\n";
	
        echo -e "$COMMAND" >> docker-compose-tmp-workers.yml;    
done
echo -e "\nAdded service entries for workers in docker-compose.yml:";
cat docker-compose-tmp-workers.yml >> docker-compose.yml;
cat docker-compose-tmp-workers.yml;
echo "$LINE_SEPARATOR";

# Adds REMOTE_WORKERS_TRIGGERED property with value jmeter-worker1, ... to jmeter-workern in .env file
echo -e "\n$PROPERTY_NAME" >> .env;
echo -e "\n  Updating .env\n$LINE_SEPARATOR\nAdded $PROPERTY_NAME at the end of the .env file\n$LINE_SEPARATOR\n";

docker-compose up;

# Cleanup folder : remove temporary files docker-compose-tmp-workers.yml, docker-compose.yml and .env
echo "Removing auto-generated temporary file docker-compose-tmp-workers.yml";
rm docker-compose-tmp-workers.yml

echo "Removing auto-generated file docker-compose.yml";
rm docker-compose.yml

echo "Removing auto-generated file .env";
rm .env;

