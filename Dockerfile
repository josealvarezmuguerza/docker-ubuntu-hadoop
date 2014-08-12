# @author jamuguerza 
# This script install a Virtual environment as:
# Ubuntu 14.04 
# openjdk-7-jdk
# maven
# Apache Hadoop 2.3.0
#
# To create the node run: "sudo docker build --rm --t hadoop-instance ."

FROM ubuntu:14.04

# Update Ubuntu packages. Run both consecutive for avoiding cache issues 
RUN apt-get update && apt-get upgrade -y

# Install Java
ENV JAVA_HOME /usr/lib/jvm/jdk
RUN apt-get install -y openjdk-7-jdk maven nano iptables
RUN ln -s /usr/lib/jvm/java-7-openjdk-amd64 $JAVA_HOME

# New hadoop user
RUN addgroup hadoop
RUN useradd -d /home/hduser -m -s /bin/bash -G hadoop hduser

# SSH configuration
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd 
RUN su hduser -c "ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''"
RUN su hduser -c "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
RUN service ssh start

# Setup Hadoop
ENV HADOOP_HOME /usr/local/hadoop
#Download hadoop tools here or paste it here
ADD hadoop-2.3.0.tar.gz ./hadoop-2.3.0.tar.gz
RUN mv hadoop-2.3.0.tar.gz/hadoop-2.3.0 /usr/local/hadoop-2.3.0
RUN rm -rf hadoop-2.3.0.tar.gz
RUN ln -s /usr/local/hadoop-2.3.0 $HADOOP_HOME
RUN rm -r /usr/local/hadoop-2.3.0
RUN mkdir -p $HADOOP_HOME/logs
ENV HADOOP_DATA /var/lib/hadoop
RUN mkdir -p $HADOOP_DATA/2.3.0/data
RUN mkdir -p $HADOOP_DATA/current/data
RUN rm -r $HADOOP_DATA/current/data
RUN ln -s $HADOOP_DATA/2.3.0/data $HADOOP_DATA/current/data


# Setup env variables
ENV PATH $PATH:$HADOOP_HOME/bin
ENV PATH $PATH:$HADOOP_HOME/sbin
ENV HADOOP_MAPRED_HOME $HADOOP_HOME
ENV HADOOP_COMMON_HOME $HADOOP_HOME
ENV HADOOP_HDFS_HOME $HADOOP_HOME
ENV YARN_HOME $HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR ${HADOOP_HOME}/lib/native
ENV HADOOP_CONF_DIR $HADOOP_HOME/etc/hadoop
ENV HADOOP_YARN_HOME $YARN_HOME

RUN echo "export JAVA_HOME=$JAVA_HOME" >> /home/hduser/.bashrc
RUN echo "export HADOOP_HOME=$HADOOP_HOME" >> /home/hduser/.bashrc
RUN echo "export PATH=$PATH" >> /home/hduser/.bashrc
RUN echo "export HADOOP_MAPRED_HOME=$HADOOP_HOME" >> /home/hduser/.bashrc
RUN echo "export HADOOP_COMMON_HOME=$HADOOP_HOME" >> /home/hduser/.bashrc
RUN echo "export HADOOP_HDFS_HOME=$HADOOP_HOME" >> /home/hduser/.bashrc
RUN echo "export YARN_HOME=$HADOOP_HOME" >> /home/hduser/.bashrc
RUN echo "export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native"  >> /home/hduser/.bashrc
RUN echo "export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop" >> /home/hduser/.bashrc
RUN echo "export HADOOP_YARN_HOME=$YARN_HOME" >> /home/hduser/.bashrc


# Configure HDFS
RUN sed 's/<\/configuration>/\n  <property>\n    <name>fs.defaultFS<\/name>\n    <value>hdfs:\/\/localhost:9000<\/value>\n  <\/property>\n<\/configuration>/'  $HADOOP_HOME/etc/hadoop/core-site.xml > $HADOOP_HOME/etc/hadoop/core-site.xml-tmp | mv $HADOOP_HOME/etc/hadoop/core-site.xml-tmp $HADOOP_HOME/etc/hadoop/core-site.xml

# configure hdfs-site.xml file
RUN sed 's/<\/configuration>/\n  <property>\n    <name>dfs.replication<\/name>\n    <value>1<\/value>\n  <\/property>\n  \n  <property>\n    <name>dfs.namenode.name.dir<\/name>\n    <value>file:\/var\/lib\/hadoop\/current\/data\/hdfs\/namenode<\/value>\n  <\/property>\n  \n  <property>\n    <name>dfs.datanode.name.dir<\/name>\n    <value>file:\/var\/lib\/hadoop\/current\/data\/hdfs\/datanode<\/value>\n  <\/property>\n<\/configuration>/' $HADOOP_HOME/etc/hadoop/hdfs-site.xml > $HADOOP_HOME/etc/hadoop/hdfs-site.xml-tmp | mv $HADOOP_HOME/etc/hadoop/hdfs-site.xml-tmp $HADOOP_HOME/etc/hadoop/hdfs-site.xml

# configure hadoop-env.sh file
RUN sed 's/export JAVA_HOME=${JAVA_HOME}/export JAVA_HOME=\/usr\/lib\/jvm\/jdk/' $HADOOP_HOME/etc/hadoop/hadoop-env.sh > $HADOOP_HOME/etc/hadoop/hadoop-env.sh-tmp
RUN sed -e'/^export JAVA_HOME=\/usr\/lib\/jvm\/jdk/a export HADOOP_OPTS=-Djava.net.preferIPv4Stack=true' $HADOOP_HOME/etc/hadoop/hadoop-env.sh-tmp > $HADOOP_HOME/etc/hadoop/hadoop-env.sh

RUN mkdir -p $HADOOP_DATA/current/data/hdfs/namenode
RUN mkdir -p $HADOOP_DATA/current/data/hdfs/datanode

# Configure YARN
#configure yarn-site.xml file
sed 's/<\/configuration>/ \n  <property>\n    <name>yarn.nodemanager.aux-services<\/name>\n    <value>mapreduce_shuffle<\/value>\n  <\/property>  \n\n  <property>\n    <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class<\/name>\n    <value>org.apache.hadoop.mapred.ShuffleHandler<\/value>\n  <\/property>  \n\n  <property>\n    <name>yarn.nodemanager.resource.cpu-vcores<\/name>\n    <value>4<\/value>\n  <\/property>  \n\n<\/configuration>/' $HADOOP_HOME/etc/hadoop/yarn-site.xml > $HADOOP_HOME/etc/hadoop/yarn-site.xml-tmp | mv $HADOOP_HOME/etc/hadoop/yarn-site.xml-tmp $HADOOP_HOME/etc/hadoop/yarn-site.xml


#configure mapred-site.xml file
RUN sed 's/<\/configuration>/\n  <property>\n    <name>mapreduce.framework.name<\/name>\n    <value>yarn<\/value>\n  <\/property>\n\n<\/configuration>/'  $HADOOP_HOME/etc/hadoop/mapred-site.xml > $HADOOP_HOME/etc/hadoop/mapred-site.xml-tmp | mv $HADOOP_HOME/etc/hadoop/mapred-site.xml-tmp $HADOOP_HOME/etc/hadoop/mapred-site.xml


# Configure directory ownership
RUN chown -R hduser:hadoop /home/hduser
RUN chown -R hduser:hadoop $HADOOP_HOME/
RUN chown -R hduser:hadoop $HADOOP_DATA/
RUN chmod 1777 /tmp

# Format namenode
RUN su hduser -c "$HADOOP_HOME/bin/hdfs namenode -format"

# Copy start & stop hadoop scripts
ADD commands/start-hadoop.sh ./start-hadoop.sh
ADD commands/stop-hadoop.sh ./stop-hadoop.sh
RUN mv ./start-hadoop.sh /usr/local/hadoop/bin/start-hadoop.sh
RUN mv ./stop-hadoop.sh /usr/local/hadoop/bin/stop-hadoop.sh

# open HDFS ports
EXPOSE 9000 50010 50020 50070 50075 50090 50470 50475 

# open YARN ports
EXPOSE 8088 8032 50060

#star-hadoop.sh starts hadoop as hduser
CMD ["/bin/bash", "start-hadoop.sh"]
