#! /bin/bash
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
add-apt-repository ppa:couchdb/stable
apt-get update
apt-get install -y tomcat8 nodejs-legacy npm openjdk-8-jdk mongodb-org couchdb maven
npm install -g swagger
npm install -g ant

# start and enable the  mongo
systemctl start mongod.service
systemctl enable mongod.service

# configure couchdb
sed -ie "s@bind_address =@bind_address = 0.0.0.0@g" /etc/couchdb/default.ini
sed -ie "s@;bind_address =@bind_address = 0.0.0.0@g" /etc/couchdb/local.ini

service couchdb restart
