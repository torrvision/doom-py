# FROM defines the base image
FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04

######################################
# SECTION 1: Essentials              #
######################################

# Set up SSH server (https://docs.docker.com/engine/examples/running_ssh_service/)
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:source' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

#Fix SSH mode issue
RUN echo "export PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:\$PATH" >> /root/.bashrc
RUN echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/nvidia/lib:/usr/local/nvidia/lib64" >> /root/.bashrc

#Update apt-get and upgrade
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils # Fix 
RUN apt-get -y upgrade

#Install python3 pip3
RUN apt-get -y install python3
RUN apt-get -y install python3-pip
RUN pip3 install pip --upgrade
RUN pip3 install numpy scipy

#Install python2.7  pip
RUN apt-get -y install python2.7
RUN wget https://bootstrap.pypa.io/get-pip.py && python2.7 get-pip.py
RUN pip install pip --upgrade
RUN pip install numpy scipy

# Set up ssh keys in order to be able to checkout TorrVision
ADD ./install/ssh-keys /root/.ssh
RUN chmod -R 600 /root/.ssh
RUN ssh-keyscan github.com >> ~/.ssh/known_hosts

#Set everything up for user "user"
RUN mkdir /home/user
RUN cp -R /root/.ssh /home/user/.ssh
RUN chmod -R 600 /home/user/.ssh

# set up directories

######################################
# SECTION 2: CV packages             #
######################################

RUN apt-get install -y git

RUN mkdir /home/user/libs
WORKDIR /home/user/libs
RUN git clone git@github.com:torrvision/doom-py.git

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y  software-properties-common && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer && \
    apt-get clean

RUN export JAVA_HOME=/usr/lib/jvm/java-8-oracle >> /root/.bashrc && export JAVA_HOME=/usr/lib/jvm/java-8-oracle >> /home/user/.bashrc

RUN apt-get install -y cmake libboost-all-dev libsdl2-dev
RUN apt-get install -y python-numpy cmake zlib1g-dev libjpeg-dev libboost-all-dev gcc libsdl2-dev wget unzip

#RUN cd /doom && cmake -DBUILD_PYTHON3=ON

############################################
## SECTION: Additional libraries and tools #
############################################

RUN apt-get install -y vim
RUN pip3 install easydict jupyter joblib pandas

############################################
## SECTION: Final instructions and configs #
############################################

#RUN apt-get install -y libcanberra-gtk-module
#RUN pip install matplotlib
#RUN pip3 install pyyaml

# set up matplotlibrc file so have Qt5Agg backend by default
RUN mkdir /root/.matplotlib && touch /root/.matplotlib/matplotlibrc && echo "backend: Qt5Agg" >> /root/.matplotlib/matplotlibrc

# Fix some linux issue
ENV DEBIAN_FRONTEND teletype

# Expose ports
EXPOSE 22
EXPOSE 8888

#Start SSH server
CMD ["/usr/sbin/sshd", "-D"]

