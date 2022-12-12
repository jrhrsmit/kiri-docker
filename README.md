
# Kiri Docker

Kiri Docker is a convenient and easy way to run [Kiri](https://github.com/leoheck/kiri) with a Docker image.

> Kiri repo is not necessary to run Kiri Docker

Kiri Docker works by linking the user project inside the docker. The resulting files are already accessible in the host system making simple to use the host browser to visualize the generated files.

The existing kiri image is hosted in Docker Hub here https://hub.docker.com/repository/docker/leoheck/kiri

# Getting the existing docker image

There is a docker image prepared and ready for Kiri. It can be accessed through this repo with:

```bash
gh repo clone leoheck/kiri-docker
make docker_pull
```

Alternatively, this is the latest image file
```bash
docker pull leoheck/kiri:latest
```

# Building your own docker image

Alternatively, you can also build the docker image yourself

```bash
gh repo clone leoheck/kiri-docker
cd kiri-docker
make build
```

# Environment

Download or build the docker image and then set your PATH to this repo with:

```bash
export PATH="$(pwd)/kiri-docker/"
```

# Using Kiri (docker)

To run kiri on your Kicad project repository:

```bash
kiri PROJECT_PATH [KIRI_PARAMETERS]
```

or, alternatively, to go inside the container, call kiri without any parameters.

```bash
kiri
```

# Example

This example launches kiri (docker), passing the path of the project and kiri `-r` flag to clean old files.

```bash
kiri "/home/lheck/Documents/assoc-board" -r
```
