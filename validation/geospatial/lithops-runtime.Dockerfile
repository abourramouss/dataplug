# Define custom function directory
ARG FUNCTION_DIR="/function"

FROM python:3.10-bullseye as build-image

# Include global arg in this stage of the build
ARG FUNCTION_DIR

# Install aws-lambda-cpp build dependencies
RUN apt-get update && \
  apt-get install -y \
  g++ \
  make \
  cmake \
  unzip \
  libcurl4-openssl-dev

# Copy function code
RUN mkdir -p ${FUNCTION_DIR}

# Update pip
RUN pip install --upgrade --ignore-installed pip wheel six setuptools

# Install the function's dependencies
RUN pip install --upgrade --no-cache-dir --ignore-installed \
    --target ${FUNCTION_DIR} \
        awslambdaric \
        boto3 \
        redis \
        httplib2 \
        requests \
        numpy \
        scipy \
        pandas \
        pika \
        kafka-python \
        cloudpickle \
        ps-mem \
        tblib \
        laspy


FROM python:3.10-bullseye

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

RUN apt-get update && \
        apt-get upgrade -y && \
        apt-get install -y --no-install-recommends \
        pdal

RUN pip install --upgrade --no-cache-dir --ignore-installed \
    --target ${FUNCTION_DIR} \
        PDAL \
        rasterio \
        laspy[lazrs,laszip]

# Add Lithops
COPY lithops_lambda.zip ${FUNCTION_DIR}
RUN unzip lithops_lambda.zip \
    && rm lithops_lambda.zip \
    && mkdir handler \
    && touch handler/__init__.py \
    && mv entry_point.py handler/

# Put your dependencies here, using RUN pip install... or RUN apt install...

ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "handler.entry_point.lambda_handler" ]