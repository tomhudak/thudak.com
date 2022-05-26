---
layout: post
title: "SQL Server — Should I use varchar(n), varchar(8000) or varchar(MAX)?"
permalink: /blog/2019-01-26-sql-server-should-i-use-varchar-n-varchar-8000-or-varchar-max/
date: 2019-01-26 14:00:00 +0100
categories: sql server varchar nvarchar
description: "A brief summary to help you decide if you run into this."
comments: true
---

![SQL](/assets/2019-01-26-sql-varchar.jpeg)

During my career I have encountered situations when I had to define a new table column for storing string data and found some confusion in the heads (including mine) when it comes to picking between `varchars` and `nvarchars` or 8000s and MAXes. I would like to clear some of that mist.

If you are looking for what's the difference between `char` and `varchar` or `varchar` and `nvarchar` there is a pretty clean explanation [here](https://stackoverflow.com/questions/144283/what-is-the-difference-between-varchar-and-nvarchar). When you need to decide what length you should use for storing your string data that's another story.

### TL;DR

Use `nvarchar(n)` if you know that your data is not longer than 4000 characters and want to be 100% sure to be very performant (or pick 8000 lengths if you are sure you don't use Unicode characters and can use `varchar`).

## Reasons for using varchar(n)
- Your data is stored physically in row therefore have a more performant execution plan on it.
- You can create indexes on your column.

## What's up with varchar(8000)?
The max number for n is 8000 that you can specify for `varchar`. Reason being that the **maximum length you can store in row is 8 kB**, and every character in `varchar` takes 1 byte.

> The max for `nvarchar` is `nvarchar(4000)` since that one takes 2 bytes per char.

## About varchar(MAX)
- If your data is longer than 8000 characters varchar(MAX) is what you need. You can store up to **2GB** size of data this way.
- In `varchar(MAX`) fields if your data size is shorter than 8000 characters your data is stored in row automatically (therefore the data execution is faster).
- Over 8000 characters your data is considered to be `text` and stored out of row, and becoming (somewhat) slower to work with.
- You cannot create indexes on `varchar(MAX)` columns.

## So which one should I use?
If you are unsure about your data length and your database is not heavily used you should be fine with `varchar(MAX)` values. If you are storing Unicode characters, go with `nvarchar(MAX)`. The same applies if you're unsure about it. If your data can vary over and under the 8k you should still be fine with it in most cases.

If you know your maximum length of your stored data, always go with `varchar(n)`, (where n is the max lengths of your data). And again if you are unsure whether you are storing Unicode chars or not, go with `nvarchar`.

If this post was any help of you please have a feedback by commenting, giving a clap, follow or share. Thanks!

This post is also published on [Medium](https://medium.com/@tamashudak/during-my-career-i-have-encountered-situations-when-i-had-to-define-a-new-table-column-for-storing-3c6c58078417).
