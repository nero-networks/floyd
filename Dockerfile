FROM node:6
RUN mkdir ./home/floyd
#cd' to dir and use as base from now on
WORKDIR ./home/floyd
#start with package.json & npm i for caching node nodules in container.
COPY ./package.json ./package.json
RUN npm install
#copy everything from floyd to /home/floyd.
#this overwrites package.json..we don't care.
COPY . .
RUN ./floyd-build.sh
ENTRYPOINT ./bin/floyd
