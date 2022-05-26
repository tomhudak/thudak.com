---
layout: default
title: "Projects"
description:  "My learning and pet projects"
permalink: /projects
include: true
---

# Learning projects

## Todo List APIs & Frontends

Todo List is a great way to go through the basic capabilities and behaviors of a programming language. What you can mostly find on the internet is either just an API or just a front-end that is using local-storage. 

I'm aiming for implementing APIs in various languages but having the same endpoints and responses. On the other side I'm implementing front-end solutions that are submitting HTTP calls to these APIs and having the same visual outlook. With this (supposedly) any front-end should be working with any of the APIs.

[![Todo list frontend](/assets/todolist.png)](/assets/todolist.png)

With this setup, besides the language basics, I can get to know how routing, CRUD API endpoints and database connections are working (on backend), how HTTP connections, error handling and two-way data binding behaves (on frontend).

#### API

- Go API [go-todolist-api](https://github.com/tomhudak/go-todolist-api) - Learned golang basics, routing, ORM ([gorm](https://gorm.io/)) connection to MySQL. Also learned how to use [Dev Containers for VS Code](//blog/2021-11-16-containerize-your-development-environment-with-visual-studio-code/)
- Node.js API [node-todolist-api](https://github.com/tomhudak/node-todolist-api) - Refreshed my Node.js basics, routing, cors, ODM ([mongoose](https://mongoosejs.com/)) connection to MongoDB.

#### Frontend

- Angular Frontend [ng-todolist-fe](https://github.com/tomhudak/ng-todolist-fe) - Learned the differences from AngularJS, HTTP handling.
- React Frontend [react-todolist-fe](https://github.com/tomhudak/react-todolist-fe) - Learned React basics, HTTP handling.

## This site

This site, besides sharing my stuff was created to learn [Jekyll](https://jekyllrb.com/) some CSS, and [Github Actions](https://github.com/features/actions). Source can be found at [github.com/tomhudak/tomhudak.github.io](https://github.com/tomhudak/tomhudak.github.io)