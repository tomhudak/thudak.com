---
layout: post
title: "Containerize Your Development Environment With Visual Studio Code"
permalink: /blog/2021-11-16-containerize-your-development-environment-with-visual-studio-code/
date: 2021-11-16 8:00:00 +0100
categories: visual studio core remote container docker compose
description: "A brief introduction to show the potential VS Code Dev Containers have."
comments: true
published: true
image:
    path: assets/2021-11-16-dev-containers/0-banner.jpeg
    width: 730
    height: 430
---

![Containerize everything!](/assets/2021-11-16-dev-containers/0-banner.jpeg)

Have you ever struggled hours (or even days!) with setting up your development environment when you joined a new project? One of your project only works with Node.js 10 but the other one requires 14+? Of course there is are tools for quickly switching versions (like [nvm](https://github.com/nvm-sh/nvm)), but it is much better to get everything working in an instant. Visual Studio Code is trying to utilize Docker to help collecting all of your dependencies and run everything in containers, including your application.
How is it done? Let's find out!

## Prerequisites

- [Visual Studio Code](https://code.visualstudio.com/)
- [Docker](https://www.docker.com/get-started)
- [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) VS Code extension

## Quick setup

The full example can be found [here](https://github.com/tomhudak/node-dev-container-hello).

Assuming you have the prerequisites installed, in order to kick start a new project you need to do the following steps. In this tutorial I am going to create a Node.js Hello-world project.

- Create a folder somewhere in hard drive (I've named it `node-dev-container-hello`)
- Open Visual Studio Code and open this folder.
- Make sure you have your Docker up and running.
- You can verify, that you have Remote - Containers extension installed that you have the green button in the bottom left corner of your VS Code.
- Click on it, then click 'Reopen in container'.

[![Reopen in container](/assets/2021-11-16-dev-containers/1-reopen-in-container.png)](/assets/2021-11-16-dev-containers/1-reopen-in-container.png)

- Select your desired language, version, and additional components (In my example I've selected `Node.js` and version 16 without additional components)

Your container is now being built then your project should be initialized.

As a demo, let's create an `app.js` file in our folder.
```js
const express = require('express')
const app = express()
const port = 3000

app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`)
})
```

Now you need to install `express` for our app, let's open a terminal for this. 

[![Reopen in container](/assets/2021-11-16-dev-containers/2-terminal.png)](/assets/2021-11-16-dev-containers/2-terminal.png)

As you can see, the terminal session is not running on your machine, but in your container. Any command that is executed has only effect inside the container. The folder `workspaces`  is your opened working directory mounted inside the container. Every code change you do is reflected inside the container as well.

So in order to be able to run our app, you need to install `express`, let's execute:
```bash
npm install express
```
Now `express` is installed and added to your `package.json` as well.

You can start your application now by typing the following to the terminal:
```bash
node app.js
```

And your containerized app is up and running!

[![Reopen in container](/assets/2021-11-16-dev-containers/3-app.png)](/assets/2021-11-16-dev-containers/3-app.png)

## devcontainer.json

Now, you have a `.devcontainer` folder generated. In it, there's the `devcontainer.json` that tells Visual Studio Code some details on how to build and run the container. This includes a reference to the `Dockerfile`, can pass arguments to be run when the container is built, list the VS Code extensions that should be installed when the container is created and a lot more. 

**File:** [github.com/tomhudak/node-dev-container-hello/blob/master/.devcontainer/devcontainer.json](https://github.com/tomhudak/node-dev-container-hello/blob/master/.devcontainer/devcontainer.json)
```json
// For format details, see https://aka.ms/devcontainer.json. For config options, see the README at:
// https://github.com/microsoft/vscode-dev-containers/tree/v0.205.2/containers/javascript-node
{
	"name": "Node.js",
	"build": {
		"dockerfile": "Dockerfile",
		// Update 'VARIANT' to pick a Node version: 16, 14, 12.
		// Append -bullseye or -buster to pin to an OS version.
		// Use -bullseye variants on local arm64/Apple Silicon.
		"args": { "VARIANT": "16" }
	},

	// Set *default* container specific settings.json values on container create.
	"settings": {},

	// Add the IDs of extensions you want installed when the container is created.
	"extensions": [
		"dbaeumer.vscode-eslint"
	],

	// Use 'forwardPorts' to make a list of ports inside the container available locally.
	// "forwardPorts": [],

	// Use 'postCreateCommand' to run commands after the container is created.
	//"postCreateCommand": "npm install",

	// Comment out connect as root instead. More info: https://aka.ms/vscode-remote/containers/non-root.
	"remoteUser": "node"
}
```

It can also can refer to  a [`docker-compose.yml`](https://github.com/tomhudak/go-todolist-api/blob/master/.devcontainer/docker-compose.yml) as I have in my [go-todolist-api](https://github.com/tomhudak/go-todolist-api/blob/master/.devcontainer/devcontainer.json) project's `devcontainer.json`. (Check it our [here](https://github.com/tomhudak/go-todolist-api/blob/master/.devcontainer/devcontainer.json).)

Let me share some details on some of the lines in the above `devcontainer.json`.
- `dockerComposeFile` indicates that this container is built with a compose file.
- `service` tells VS Code that which one of the services in the `docker-compose.yml` is the dev container. 
- `postCreateCommand` runs commands after the container is created.

If you want to run this project on another machine or rebuild your container you will still need to execute `npm install` every time to install dependencies. To automate this you can add this line
```json
"postCreateCommand": "npm install",
```
and have it executed after it is built.

It is definitely worth checking out the [devcontainer.json reference](https://code.visualstudio.com/docs/remote/devcontainerjson-reference) for more on this.

## What about the database?

Since Dev Container utilizes Docker, you can just put up a `docker-compose.yml` and include all the 3rd party dependencies and tools you need. For example I have a MySQL database and a DB management webUI kicked in for my [`go-todolist-api`](https://github.com/tomhudak/go-todolist-api) project.

**File:** [github.com/tomhudak/go-todolist-api/blob/master/.devcontainer/docker-compose.yml](https://github.com/tomhudak/go-todolist-api/blob/master/.devcontainer/docker-compose.yml)
```yml
version: '3.7'

services:
  app:
      build:
        context: ..
        dockerfile: .devcontainer/Dockerfile
        args:
          VARIANT: 1.17
          NODE_VERSION: none
      environment:
        PORT: 3010
      ports:
        - 3010:3010
      volumes:
        - ..:/workspace
      user: vscode
      command: sleep infinity

  adminer:
    image: adminer
    restart: always
    ports:
      - 3080:8080

  mysql:
    image: mysql:5.6
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
    ports:
      - 3306:3306
```

## Resources

Basic example: [github.com/tomhudak/node-dev-container-hello](https://github.com/tomhudak/node-dev-container-hello)

Docker-compose example: [github.com/tomhudak/go-todolist-api](https://github.com/tomhudak/go-todolist-api)

## Final thoughts

Although VS Code Dev Containers still has a number of issues, especially with extensions (for example the `golang` linter cannot identify packages installed in `postCreateCommand` until you edit those lines or some of the spell checkers cannot cope with files opened in containers), I still think in the (not so far) future, most of our project are going to be containerized and can be opened in any suitable IDE with one click so it is worth keeping an eye on the improvements around Dev Containers.

Also worth mentioning the Docker itself has the [support](https://docs.docker.com/desktop/dev-environments/) for Dev Environments (at the time of writing this still in preview).

If you liked this post or have any thoughts on this, I appreciate your feedback. Thank you!




