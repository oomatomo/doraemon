FROM centos:centos6
MAINTAINER oomatomo ooma0301@gmail.com

# install package
RUN rpm -Uhv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum update -y

# time
ENV TZ JST-9

# nodejs npm
RUN yum install -y tar bzip2 git
RUN curl --silent --location https://rpm.nodesource.com/setup_5.x | bash -
RUN yum install -y nodejs
RUN yum install -y gcc-c++ make

# change hubot user
RUN useradd -d /hubot -m -s /bin/bash -U hubot
USER    hubot
WORKDIR /hubot

# npm install
COPY package.json ./
RUN npm install

COPY ./bin/hubot ./bin/hubot
COPY hubot-scripts.json ./
COPY external-scripts.json ./
COPY ./scripts ./scripts

EXPOSE 8080
CMD ["bin/hubot", "-a", "slack", "-n", "doraemon"]
