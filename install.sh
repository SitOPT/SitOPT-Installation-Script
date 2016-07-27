#! /bin/bash
# stops all node, npm, actionhero and nodejs instances on the server.
# (re)installs node_modules for each node app.
USER=$(whoami)
ORIG_USER=${SUDO_USER}

if [[ ${USER} != "root" ]]; then
  echo "Please start the script as root"
  exit 1
fi

# echoes current time and date for logging purposes
date

# Prepare databases for Installation
if [[ ! -f db_setup.sh ]]; then
  sudo -u ${ORIG_USER} wget https://raw.githubusercontent.com/SitOPT/SitOPT-Installation-Script/master/db_setup.sh
fi

mongo RBS --host localhost --eval 'db.createUser({"user": "RBS", "pwd": "RBS", "roles": ["readWrite"]})'
sudo -u ${ORIG_USER} chmod +x db_setup.sh
sudo -u ${ORIG_USER} ./db_setup.sh
  

# clone repositories

# rmp
sudo -u ${ORIG_USER} git clone https://github.com/SitOPT/Resource-Management-Platform.git

# situation dashboard
sudo -u ${ORIG_USER} git clone https://github.com/SitOPT/Situation-Dashboard.git

# situation model management
sudo -u ${ORIG_USER} git clone https://github.com/SitOPT/Situation-Model-Management.git

# situation template mapping (Node-Red)
sudo -u ${ORIG_USER} git clone https://github.com/SitOPT/Situation-Template-Mapping_Node-Red.git

# situation template mapping (Esper)
sudo -u ${ORIG_USER} git clone https://github.com/SitOPT/Situation-Template-Mapping_Esper.git

# modeling tool
sudo -u ${ORIG_USER} git clone https://github.com/SitOPT/Situation-Template-Modeling-Tool.git

# schema files
sudo -u ${ORIG_USER} git clone https://github.com/SitOPT/Situation-Template-Schema.git

# kill running processes to avoid conflicts
pkill -9 nodejs
pkill -9 npm
pkill -9 actionhero
pkill -9 node

# build the mapping library
cd Situation-Template-Mapping_Node-Red
rm -rf src/situationtemplate
sudo -u ${ORIG_USER} xjc -d src -p situationtemplate.model situation_template.xsd
sudo -u ${ORIG_USER} ant
# copy the jar to the needed locations
cp situation_template_v01.jar ../Situation-Dashboard/public/nodeRed/mappingString.jar
cp situation_template_v01.jar ../Situation-Template-Modeling-Tool/lib

# build the modeling tool
cd ..
cd Situation-Template-Modeling-Tool
rm -rf src/model
sudo -u ${ORIG_USER} xjc -d src -p model res/situation_template.xsd
sudo -u ${ORIG_USER} ant
# copy the war file and the WebContent directory to the default tomcat8 locations
cp -R WebContent/* /var/lib/tomcat8/webapps/SitTempModelingTool
cp SitTempModelingTool.war /var/lib/tomcat8/webapps
/etc/init.d/tomcat8 restart

# build Sitdb + api
cd ..
cd Situation-Model-Management
rm -rf node_modules
sudo -u ${ORIG_USER} npm install
sudo -u ${ORIG_USER} node_modules/.bin/swagger project start >> Sitdb.log 2>&1 &

# build rmp
cd ..
cd Resource-Management-Platform
rm -rf node_modules
sudo -u ${ORIG_USER} npm install
sudo -u ${ORIG_USER} npm start >> rmp.log 2>&1 &

# build the situation dashboard
cd ..
cd Situation-Dashboard
rm -rf node_modules
sudo -u ${ORIG_USER} npm install
sudo -u ${ORIG_USER} nodejs server.js >> dashboard.log 2>&1 &

cd ../..

# check if node-red directory exists if not create it and install node-red into it
if [[ ! -d node-red ]]; then
  sudo -u ${ORIG_USER} mkdir node-red
  cd node-red
  sudo -u ${ORIG_USER} npm install node-red
fi

# start node-red
cd node-red/node_modules/.bin
sudo -u ${ORIG_USER} ./node-red 2>&1 > /dev/null &
