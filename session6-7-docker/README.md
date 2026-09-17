# Docker Images - Hello World Applications

## Overview

This practical focused on creating and running simple web applications using Docker.

Six applications were containerized:

1. Node.js
2. Python Flask
3. Java
4. Apache HTTP Server
5. React
6. Nginx

Each application has its own folder and Dockerfile. The images were built successfully, the containers were started, and the applications were verified in a web browser.

---

## Docker Concepts Practiced

| Instruction | Purpose                                                  |
| ----------- | -------------------------------------------------------- |
| `FROM`      | Specifies the base image.                                |
| `WORKDIR`   | Sets the working directory inside the container.         |
| `COPY`      | Copies application files into the image.                 |
| `RUN`       | Executes commands while building the image.              |
| `EXPOSE`    | Documents the port used by the application.              |
| `CMD`       | Specifies the default command when the container starts. |

### Docker Build

The `docker build` command creates an image from a Dockerfile:

```bash
docker build -t <image-name> .
```

### Docker Run

The `docker run` command creates and starts a container:

```bash
docker run -d --name <container-name> -p <host-port>:<container-port> <image-name>
```

### Port Mapping

Port mapping connects a host port to a port inside the container. For example:

```text
Host port 5001 -> Container port 5000
```

This allows the Python application running on port `5000` inside the container to be accessed through port `5001` on the host.

## Verification

```bash
docker images
docker ps
```

The images and running containers can be viewed with these commands.

## Directory Structure

```text
session6-7-docker/
├── Apache-app/
│   ├── Dockerfile
│   └── index.html
├── java-app/
│   ├── Dockerfile
│   └── Main.java
├── node-app/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── python-app/
│   ├── Dockerfile
│   └── app.py
├── React-app/
│   ├── Dockerfile
│   ├── index.html
│   ├── package.json
│   └── src/main.jsx
├── nginx-app/
│   ├── Dockerfile
│   └── index.html
├── screenshots/
└── README.md
```

## Result

Six different applications were successfully containerized using Docker. Each application was built into a Docker image, run as a container, and verified through a web browser.

This practical provided hands-on experience with Dockerfiles, Docker images, containers, port mapping, static web servers, backend services, and frontend builds.
