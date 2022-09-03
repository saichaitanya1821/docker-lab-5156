# General references for this lab:
#   - Dockerfile instruction reference https://docs.docker.com/engine/reference/builder/
#   - Dockerfile cheatsheet https://kapeli.com/cheat_sheets/Dockerfile.docset/Contents/Resources/Documents/index
##################################
# It's time to create our first Docker image! Please use the references
# above and linked throughout the file if you get stuck! Additionally, don't
# be afraid to use CampusWire to ask questions! WARNING: Building a Dockerfile
# can take a fair bit of time, therefore it can be useful to comment out
# everything AFTER the TODO you are currently working on! Once you have succesfully
# built a given layer or Docker instruction (e.g., FROM, LABEL, RUN, ect) then this
# layer should be cached and run immdiately next time unless a layer or instruction 
# before it is changed!

################# TODO 1 #################
# Let's start by using Ubuntu as our base image. In order to do so we use the 
# FROM command to state the base image we wish to build ontop of. 
# This means any packages, software, files, ect created in the base image 
# will be included in our image!
#
# 1. Use Ubuntu version 18.04 as the base image. Recall, that the version of
#    Ubuntu is specified by the tag after the colon ':' of the docker image! 
#    See Ubuntu's Dockerhub page to see which image tag corresponds to version 
#    18.04 using the following link: https://hub.docker.com/_/ubuntu/?tab=tags&page=1&ordering=last_updated.
FROM ubuntu:18.04


################# TODO 2 #################
# It's time to specify who is maintaining our Dockerfile. This acts as 
# as a form of meta-data that let's others see who is maintaining the Dockerfile.
#
# 1. Given the LABEL command set the value of the "maintainer" key equal to 
#    your first and last name. For example, "maintainer"="John Doe".
LABEL maintainer="Chaitanya Ch"


##################################
# Now, let's set some arguments that will be used throughout the Dockerfile.
# Arguments (ARG) are variables that are only available to the Dockerfile
# during run time. Meaning, any ARG that is defined is only available when building
# an image with the 'docker build' command. Arguments can be useful as 
# they can be modified at run-time without changing the Dockerifle 
# (see Docker ARG official docs below).
#
# First, we set our default HOST_UID and HOST_GID which will determine our user 
# ID and GID. These IDs help define permissions Docker container will have access
# to when it is finally created. Additionally, if you are on a Linux distro, it 
# can be useful to make sure that the UID and GID match the host computer's UID 
# and GID to prevent any potential errors when mounting code into your container. 
#
# References: 
#   - UID and GID in Linux: https://medium.com/@gggauravgandhi/uid-user-identifier-and-gid-group-identifier-in-linux-121ea68bf510 
#   - Docker ARG official docs https://docs.docker.com/engine/reference/builder/#arg
ARG HOST_UID="1000"
ARG HOST_GID="100"

################# TODO 3 #################
# Next, we need to make a HOST_USER which will act as the name of the user we 
# will create later on!
#
# 1. Create an argument using the ARG instruction called HOST_USER which is set
#    to your first name. For example, HOST_USER="john".
ARG HOST_USER="Chaitanya"

##################################
# Here we specify some environment variables which WILL be available to our container after
# building the image, this is unlike the ARG instruction. The variables set below are just common 
# environmental variables that Linux, in this case Ubuntu, tends to set regarding 
# our HOME directory, CONDA version, CONDA directory, USER name, UID, and GID. 
# 
# Also, it is worth noting that the '\' is used to indicate the command continues
# onto the next line. We can use '\' to chain together commands to help reduce 
# the number of layers in our image. Further, we use the dollar sign followed by an ARG or ENV
# variable to refer to a prior set ARG or ENV variable. For instance, $HOST_USER
# is used to refer the HOST_USER argument and thus will use the value stored
# within said argument.
#
# References:
#   - Docker ARG vs ENV https://vsupalov.com/docker-arg-vs-env/
#   - Why we chain commands together with && or \: https://tinyurl.com/cs6972dw 
ENV HOME=/home/$HOST_USER \
    MINICONDA_VERSION=4.6.14 \
    CONDA_VERSION=4.6.14 \
    CONDA_DIR=/home/$HOST_USER/miniconda \
    USER=$HOST_USER \
    UID=$HOST_UID \ 
    GID=$HOST_GID
    
##################################
# Once again, here we are appending our PATH environmental variable with the soon
# to be locations of python and conda bin files. Due to PATH using some of the 
# prior set environmental variables the PATH must be on its own line or the 
# prior set variables (like CONDA_DIR or HOME) will not be recognized.
# This is just a small caveat we have to deal with and keep in mind. 
# 
# Note, we use ${} to refer to the ENV variables where the {} acts as a disambiguation 
# mechanism. In other words, it defines the beginning and end of the ENV
# or ARG variable we wish use when they appear in the middle of a string or command. 
#
# References:
#   - Overview of PATH: https://www.baeldung.com/linux/path-variable
#   - What does ${} mean in Bash: https://tinyurl.com/3bex7frc 
ENV PATH=${CONDA_DIR}/bin:${HOME}/.local/bin:${PATH}

##################################
# Now, we need to create our user so we don't have root privileges when our
# Docker container is created. Having root privileges can lead to big
# security risks as Docker containers are only semi-isolated. It is best practice
# to always best create a user to avoid these risks and is usually a requirement
# in an industry setting, thus it is good practice to start doing it now!
#
# References:
#   - List of useradd flag meanings https://www.computerhope.com/unix/useradd.htm
RUN groupadd -r ${HOST_USER} \
    && useradd -d /home/${HOST_USER} -g ${HOST_GID} -m -r -u ${HOST_UID} ${HOST_USER}

################# TODO 4 #################
# Next, we need to copy our conda and pip requirements text files into our container
# file system. Recall to do so we use the COPY instruction which takes as input
# the path of the all files and the path within the container file system we 
# want to copy said files. The path within the container file system should
# ALWAYS be the last path of the instruction! 
#
# 1. Use the COPY instruction to copy the pip_requirements.txt and conda_requirements.txt
#    files into into $HOME/ directory of the container filesystem. Note, we need 
#    to refer to the HOME environment variable we set earlier! Try using $HOME/
COPY pip_requirements.txt ${HOME}
COPY conda_requirements.txt ${HOME}

# References:
#   - Geeksforgeeks Docker COPY command usage: https://www.geeksforgeeks.org/docker-copy-instruction/
#   - Offical Docker COPY Docs: https://docs.docker.com/engine/reference/builder/#copy


##################################
# It's time to install some basic packages and software to help fleshout
# our environment we'll be using for coding. Below we install an simple programs
# such as an in-line text editor VIM, a GitHub for version control, CURL to 
# pull packages and files from the internet, and ca-certificates, for verifying
# packages/files pulled from the internet. Further, we also pull miniconda
# directly from the internet so that we may install it later on. Also, note that 
# the '&&'' is the Linux symbol for chaining commands together.
#
# References:
#   - Best apt-get practices for Dockerfiles https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#apt-get
RUN apt-get update && apt-get install -yq --no-install-recommends \
    # VIM is a text editor we can run in the terminal.
    vim \
    # GitHub is for version control and managing code
    git \
    # curl is for downloading files from the web.
    curl \
    # ca-certificates is a dependency of curl which verifies downloads as legit.
    ca-certificates \
    # apt-get clean cleans the apt package manager to reduce layer size.
    && apt-get clean \
    # Clears apt cache to reduce layer size 
    && rm -rf /var/lib/apt/lists/* \
    # Here we pull the minicode version we want to install where -o specifies the 
    # path and name we give to the file being downloaded
    && curl -sSL https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -o $HOME/miniconda.sh \
    # Lastly, we chown or shift privileges of the user's home directory from the 
    # root user to our defined user.
    && chown -R ${HOST_USER}:${HOST_GID} $HOME

################# TODO 5 #################
# So far we have run all the prior commands technically as the root user! This
# is fine as these commands all tend to require root privileges. However, now
# it is time to switch to our created user and start installing Anaconda and Python
# packages!
#
# 1. Switch to our created user by using the USER instruction and passing the 
#    environmental variable HOST_USER to the command. Recall, in order to refer 
#    to an an ARG or ENV variable we need to add the '$' symbol before the variable!
#
# References:
#   - Docker USER official docs https://docs.docker.com/engine/reference/builder/#user
#   - Geeksforgeeks USER instruction https://www.geeksforgeeks.org/docker-user-instruction/
USER ${HOST_USER}

################# TODO 6 #################
# Further, we need to set our working directory. To do so we need to use the 
# WORKDIR instruction which sets the working directory for the remaining 
# instructions. Further, the working directory is the path we will be automatically 
# be placed at when our container first runs.
#
# 1. Set our working directory by using the WORKDIR instruction and passing 
#    the HOME ENV variable. Recall, in order to execute refer to an o an ARG or 
#    ENV variable we need to use add the '$' symbol before the variable.
#
# References:
#   - Docker WORKDIR official docs https://docs.docker.com/engine/reference/builder/#workdir
WORKDIR ${HOME}

##################################
# Now that we have switched to our create user and set our working directory
# as our user's home directory we can now install Anaconda! Note, that every time
# we install a file we downloaded or copied into a container it is best practice
# to then remove said file using the 'rm' command as this helps reduce the Docker
# image size!
RUN /bin/bash ./miniconda.sh -bp $CONDA_DIR \
    && rm miniconda.sh

################# TODO 7 #################
# Since Anaconda is now installed now we can configure and install Anaconda
# settings. Below we start off by appending some popular channels which allows
# us to install a wider verity of packages. Further, we need to install any
# requirements in our conda_requirements.txt file. 
#
# Note, as of right now the conda_requirements.txt file is empty as we install
# all the important packages via pip and adding more packages will only increase
# the time it takes to build our Docker image. However, feel free to add any files 
# to the conda_requirements.txt file as you please.
#
# 1. Add the "conda install" command using the --yes and --file flags so that 
#    any packages contained within conda_requirements.txt file are installed.
#    Be sure to add the '&&' before the command and the '\' at the end of the 
#    command as this RUN command to runs multiple command, given it is not there already!
# 2. Add the 'rm' command to remove the conda_requirements.txt. Be 
#    sure to add the '&&' before the command to indicate it is part of the
#    chain of commands for RUN, given it is not there already! THIS IS OUR LAST 
#    COMMAND SO WE DONT NEED TO ADD '\' OTHERWISE AN ERROR WILL BE THROWN!
#
# References:
#   - Conda install official docs https://docs.conda.io/projects/conda/en/latest/commands/install.html
#   - Conda requirements file install https://stackoverflow.com/questions/51042589/conda-version-pip-install-r-requirements-txt-target-lib
#   - Linux how to remove a file using 'rm' https://www.educba.com/linux-rm-command/
RUN  conda config --system --prepend channels conda-forge \
    && conda config --system --prepend channels anaconda \
    ##### TODO 7-1 #####
    && conda install --yes --file conda_requirements.txt \
    && conda clean --all -f -y \
    ##### TODO 7-2 #####
    && rm conda_requirements.txt 

################# TODO 8 #################
# Next up we need to install any of our pip requirements in the 
# pip_requirements.txt file.
#
# 1. Add the "pip install" command using the --user, -r, and  --no-cache-dir flags 
#    so that any packages contained within pip_requirements.txt file are installed.
#    Note the --user flag installs the packages for our created user ONLY! Further,
#    the --no-cache-dir helps remove any unneeded files keeping our docker image
#    as small as possible! Be sure to add the '&&' before the command and the 
#    '\' at the end of the command as this RUN command runs multiple commands,
#    given it is not there already!!
# 2. Run the command line 'rm' command to remove the pip_requirements.txt.
#    Be sure to add the '&&' before the command to indicate it is 
#    part of the chain of commands for RUN, given it is not there already!
RUN pip install --upgrade pip \
    ##### TODO 8-1 #####
    && pip install --user -r pip_requirements.txt --no-cache-dir \
    ##### TODO 8-2 #####
    && rm pip_requirements.txt 

##################################
# This line is simply for aesthetic purposes. When we attach to our docker container 
# this makes the command-line path colorful which can help remind us we are attached
# to a container and is easier on the eyes!
#
# References:
#   - Colorful Terminal https://linoxide.com/how-tos/change-linux-shell-prompt-with-different-colors/
RUN echo 'export PS1="\[\033[1;36m\]\u@\[\033[1;32m\]\h:\[\033[1;34m\]\w\[\033[0m\]\$ "' >> ${HOME}/.bashrc

################# TODO 9 #################
# Lastly, we need to add a command that our container will run upon its creation.
# Since we are using Docker as a portable environment we want to use the /bin/bash
# command which allows us to use the '-it' flags for 'docker run' so we can attach
# to our container and get an interactive shell or terminal!
# 
# 1. Add the CMD instruction and pass /bin/bash to it!
#
# References:
#   - Run bash to create a interactive terminal for a container: https://tinyurl.com/45u3y9ru
CMD /bin/bash


################# TODO 10 #################
# Now it is time to build our Docker image and run it! If you need a remind be sure to review
# the part 3 Docker video in the Canvas module.
#
# 1. Using the command line build this Dockerfile using the following command: 
#    "Docker build -t docker-lab-5156 ." command. You can adjust this command as 
#     needed but be sure to tag your Docker image as "docker-lab-5156".
# 2. After building the image let's try running the container by using the following command:
#    `docker run  -it --rm -p 8888:8888 --name docker-lab docker-lab-5156`. This should
#    automatically attach you to your newly created container where you can run the
#    Jupyter Notebook using the command `jupyter-notebook --ip 0.0.0.0` where you can try  
#    creating a notebook and importing some libraries like numpy or sklearn!
#
# Finally you'll need to push your Docker your personal Docker Hub as you'll need
# to submit a link along with the completed Dockerfile! If you didn't create a 
# Docker Hub account when installing Docker now is the time to do so. 
# Go to https://hub.docker.com/ and create an account and then sign in either through
# the command line by entering "Docker login" and then entering your credentials 
# or by signing in through the DockerDesktop GUI if you are on Windows.
#
# In order to push your image to DockerHub you will also need to retag the 
# image you just created. If you need more guidance checkout the part 4 Docker 
# video in the Canvas module.
# 1. If you haven't already, first retag the Docker image by using the following 
#    command "docker tag docker-lab-5156 <your Docker account username>/docker-lab-5156".
#    Feel free to edit this command as you please but be sure the Docker image 
#    name ends with "docker-lab-5156" (not including the tag). Note,
#    if you are on Linux you may need to add 'sudo' to the start of the command.
# 2. Push the docker image to your Docker Hub by entering the following command
#    into the command line replacing the <> with your Docker account username: 
#    "docker push <your Docker account username>/docker-lab-5156""
#    into the command line: "docker push <your Docker account username>/docker5156".
#    Note, if you are on Linux you may need to add 'sudo' to the start of the command.
#
# Points for this TODO are determined by whether or not your image has been pushed 
# to Dock Hub. Be sure to submit the link to your Docker Hub when you submit the Dockerfile!

################# SUBMIT #################
# Once you have built your image and pushed it to Docker Hub submit this 
# Dockerfile AND a link to your Docker Hub image that you just pushed!


