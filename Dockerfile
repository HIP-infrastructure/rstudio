ARG CI_REGISTRY_IMAGE
ARG TAG
ARG DOCKERFS_TYPE
ARG DOCKERFS_VERSION
FROM ${CI_REGISTRY_IMAGE}/${DOCKERFS_TYPE}:${DOCKERFS_VERSION}${TAG}
LABEL maintainer="florian.sipp@inserm.fr"

ARG DEBIAN_FRONTEND=noninteractive
ARG CARD
ARG CI_REGISTRY
ARG APP_NAME
ARG APP_VERSION

LABEL app_version=$APP_VERSION
LABEL app_tag=$TAG

WORKDIR /apps/${APP_NAME}

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \ 
    software-properties-common dirmngr wget \
    curl libpq5 libclang-dev libnss3 \
    libatk1.0-0 libatk-bridge2.0-0 libcups2 \
    libgtk-3-0 libasound2 build-essential && \
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" && \
    apt-get install --no-install-recommends -y r-base && \
    add-apt-repository ppa:c2d4u.team/c2d4u4.0+ && \
    apt-get install --no-install-recommends -y r-cran-rstan r-cran-tidyverse && \
    curl -sSO https://download1.rstudio.org/electron/bionic/amd64/rstudio-${APP_VERSION}-386-amd64.deb && \
    dpkg -i rstudio-${APP_VERSION}-386-amd64.deb && \
    rm -rf rstudio-${APP_VERSION}-386-amd64.deb && \
    apt-get remove -y --purge wget curl && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV APP_SPECIAL="no"
ENV APP_CMD="rstudio"
ENV PROCESS_NAME="rstudio"
ENV APP_DATA_DIR_ARRAY=".r R .config/rstudio"
ENV DATA_DIR_ARRAY=""

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
