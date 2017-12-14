FROM clowder/pyclowder:1
MAINTAINER Rui Liu <ruiliu@illinois.edu>

# copy requirements file
COPY requirements.txt /home/clowder/

# Install any programs needed
USER root

RUN apt-get update && apt-get -y install python-dev python-pip python-dev build-essential python-numpy software-properties-common && apt-add-repository ppa:ubuntugis/ppa && \
    apt-get -y install gdal-bin python-gdal python-scipy && \
    pip install --upgrade pip && \
    pip install -r /home/clowder/requirements.txt && \
    rm -rf /var/lib/apt/lists/*

# Switch to clowder, copy files and be ready to run
USER clowder

# command to run when starting docker
ENTRYPOINT ["/home/clowder/entrypoint.sh"]
CMD ["extractor"]

# Setup environment variables. These are passed into the container. You can change
# these to your setup. If RABBITMQ_URI is not set, it will try and use the rabbitmq
# server that is linked into the container. MAIN_SCRIPT is set to the script to be
# executed by entrypoint.sh
ENV RABBITMQ_URI="" \
    RABBITMQ_EXCHANGE="clowder" \
    RABBITMQ_VHOST="%2F" \
    RABBITMQ_QUEUE="ncsa.geotiff.metadata" \
    MAIN_SCRIPT="ncsa.image.geotiff.py"

# copy rest of the files needed
COPY entrypoint.sh *.py extractor_info.json /home/clowder/