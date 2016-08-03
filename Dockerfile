FROM ubuntu:vivid
MAINTAINER Mindboggle <anishakeshavan@gmail.com>

# Preparations
RUN ln -snf /bin/bash /bin/sh
ARG DEBIAN_FRONTEND=noninteractive

# Update packages and install the minimal set of tools
RUN apt-get update && \
    apt-get install -y curl \
                       git \
                       xvfb \
                       bzip2 \
                       unzip \
                       apt-utils \
                       gfortran \
                       fusefat \
                       liblapack-dev \
                       libblas-dev \
                       libatlas-dev \
                       libatlas-base-dev \
                       libblas3 \
                       libblas-common \
                       libopenblas-dev \
                       libxml2-dev \
                       libxslt1-dev \
                       libfreetype6-dev \
                       libpng12-dev \
                       libqhull-dev \
                       libxft-dev \
                       libjpeg-dev \
                       libyaml-dev \
                       graphviz




# Enable neurodebian
RUN curl -sSL http://neuro.debian.net/lists/vivid.de-m.full | tee /etc/apt/sources.list.d/neurodebian.sources.list && \
    curl -sSL http://neuro.debian.net/lists/vivid.us-tn.full >> /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && \
    apt-get update #&& \

# Clear apt cache to reduce image size
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Preparations
RUN ln -snf /bin/bash /bin/sh
WORKDIR /root

# Install miniconda
RUN curl -sSLO https://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh && \
    /bin/bash Miniconda-latest-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda-latest-Linux-x86_64.sh && \
    echo '#!/bin/bash' >> /etc/profile.d/nipype.sh && \
    echo 'export PATH=/usr/local/miniconda/bin:$PATH' >> /etc/profile.d/nipype.sh

ENV PATH /usr/local/miniconda/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# Add conda-forge channel in conda
RUN conda config --add channels conda-forge

RUN conda create -y -n mb-3.5 nipype python=3.5 && \
    source activate mb-3.5

#RUN conda install nipype
RUN conda install -c https://conda.anaconda.org/clinicalgraphics vtk cmake
RUN git clone https://github.com/binarybottle/mindboggle
RUN cd mindboggle && \
    python setup.py install

ENV CONDA_PATH "/usr/local/miniconda/"
ENV VTK_DIR "$CONDA_PATH/lib/cmake/vtk-7.0"
ENV vtk_cpp_tools "mindboggle/vtk_cpp_tools/bin"

RUN mkdir $vtk_cpp_tools && \
    cd $vtk_cpp_tools && \
    cmake ../ -DVTK_DIR:STRING=$VTK_DIR && \
    make

# Install ANTs
RUN mkdir -p /opt/ants && \
    curl -sSL "https://2a353b13e8d2d9ac21ce543b7064482f771ce658.googledrive.com/host/0BxI12kyv2olZVFhUcGVpYWF3R3c/ANTs-Linux_Ubuntu14.04.tar.bz2" \
    | tar -xjC /opt/ants --strip-components 1
ENV ANTSPATH /opt/ants
ENV PATH $ANTSPATH:$PATH

RUN printf '#!/bin/bash\nexport ANTSPATH=/opt/ants\nexport PATH=$ANTSPATH:$PATH' > /etc/profile.d/nipype_deps.sh

RUN echo 'source activate mb-3.5' >> /etc/profile.d/nipype.sh

#get templates and atlases we need
RUN curl -L 'https://osf.io/bx35m/?action=download' -o OASIS-30-Atropos.zip
RUN unzip OASIS-30-Atropos.zip

RUN curl -L 'https://osf.io/d2cmy/?action=download&version=1' -o OASIS-TRT-20_jointfusion_DKT31_CMA_labels_in_OASIS-30_v2.nii.gz

CMD ["/bin/bash"]
