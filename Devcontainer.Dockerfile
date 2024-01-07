# This Dockerfile is used to build the image used by the devcontainer.json file.
# This is used setting up the development environment in VS Code.
FROM swiftlang/swift:nightly-jammy

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install essentials
RUN apt-get update && \
    apt-get install -y build-essential curl git wget openssl libssl-dev

RUN mkdir /setup
WORKDIR /setup

# Install cmake form `master` branch
RUN git clone https://gitlab.kitware.com/cmake/cmake.git
WORKDIR /setup/cmake
RUN ./bootstrap && \
    make && \
    make install

RUN apt-get install -y cmake gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib

# Add non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

WORKDIR /home/$USERNAME
RUN git clone https://github.com/raspberrypi/pico-sdk.git && \
    cd pico-sdk && \
    git submodule update --init

RUN sudo apt-get install -y ninja-build

# Install Mint
# RUN cd && \
#     git clone https://github.com/yonaskolb/Mint.git &&\
#     cd Mint &&\
#     swift run mint install yonaskolb/mint
# ENV PATH="/home/${USERNAME}/.mint/bin:${PATH}"

# # Local project Mint dependencies
# COPY Mintfile /Mintfile
# RUN mint bootstrap --link --mintfile /Mintfile

# Required for non-root user with anonymous volume on these paths to be able to build
RUN sudo mkdir -p /workspace/.build && \
    sudo chown $USERNAME:$USERNAME /workspace/.build