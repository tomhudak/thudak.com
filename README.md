## Source code to [thudak.com(https://thudak.com/) site

This is the source code to my personal site [thudak.com](https://thudak.com/) built with [Jekyll](https://jekyllrb.com/) and hosted on [Github Pages](https://docs.github.com/en/pages).

## Build

Make sure to have your `.env` ready. See `.env.example` for template.

- In the dev container run `JEKYLL_ENV=production bundle exec jekyll build`
- On the source code root run `./deploy.sh`
- On the web server (running nginx) run `sudo nginx -s reload`
