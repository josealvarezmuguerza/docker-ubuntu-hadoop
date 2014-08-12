docker-ubuntu-hadoop
===============

This docker script aims to create a ~~virtual machine~~ virtual environment with the following configuration:

- Ubuntu 14.04 LTS, with updated packages
- JDK 1.7
- Apache Hadoop 2.3
- maven

You can also join a single-node-hadoop-instance running in the OS host, to this new node, since the VE is configured with open ports for this purpose. 


Requirements
===========

![image](https://d3oypxn00j2a10.cloudfront.net/0.7.0/img/nav/docker-logo-loggedout.png)

**Docker Engine**

#####[Why docker?]




Installation
===============
```java

git clone git@github.com:josealvarezmuguerza/docker-ubuntu-hadoop.git
cd docker-ubuntu-hadoop
```
Download the [hadoop-2.3.0.tar.gz] file into docker-ubuntu-hadoop/ folder

```java
docker build -rm --tag=hadoop-instance .
```


###Estimated duration
About 60 mins. (1 min machine setup + 59 mins OS packages upgrades)

Usage
===============
```java
sudo docker run -i -t -P --name nodo01 -v {any/shared/folder/in/host}:{/shared/folder/in/VM} hadoop-instance /bin/bash start-hadoop.sh
```

License
=======
Apache License, Version 2.0
http://www.apache.org/licenses/LICENSE-2.0




[Why docker?]:https://www.docker.com/whatisdocker/
[hadoop-2.3.0.tar.gz]:http://www.us.apache.org/dist/hadoop/core/hadoop-2.3.0/hadoop-2.3.0.tar.gz