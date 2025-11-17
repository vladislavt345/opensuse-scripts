#!/bin/bash

#docker
sudo zypper install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
docker --version
docker run hello-world
