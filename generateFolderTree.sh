#! /bin/bash

BASE_PATH='';

read -p 'Where do you want to generate the folder tree ? (ex: /home/user/jmeter-dockerized) ' BASE_PATH;
mkdir -p $BASE_PATH;

echo -e '\nmkdir -p jmx license properties logs/controller logs/workers results report;';
mkdir -p jmx license properties logs/controller logs/workers results report;

echo 'sudo chmod o+w -R logs/ results/ report/;'
chmod o+w -R logs/ results/ report/;

echo -e "mv jmx license properties logs results report $BASE_PATH;\n"
mv jmx license properties logs results report $BASE_PATH;

echo "tree $BASE_PATH;"
tree $BASE_PATH;

echo '';
echo 'To finalise your setup:';
echo "- Update default.env path to set ROOT_DIR=$BASE_PATH";
echo "- Place your test.jmx file into $BASE_PATH/jmx";
echo "- Place your ubik-streaming-plugin.license file into $BASE_PATH/license";
echo "- Place your user-controller.properties file into $BASE_PATH/properties";
echo "- Place your user-worker.properties file into $BASE_PATH/properties";
echo "- Place your saveservice-controller.properties file into $BASE_PATH/properties";
echo "- Place your saveservice-worker.properties file into $BASE_PATH/properties";
echo "- Run the script run-jmeter-in-docker.sh"
echo '';