FROM node:6

# floyd resides unobstructive in /opt/floyd
RUN mkdir /opt/floyd

# put the floyd command into $PATH
ENV PATH="/opt/floyd/bin:${PATH}"

# prepare NODE_PATH so floyd apps find floyd/node_modules/something
ENV NODE_PATH=/opt/floyd/node_modules

# cd to dir and use as base from now on
WORKDIR /opt/floyd

# copy everything from floyd to /home/floyd.
COPY . .

# run initial build. takes care of npm
RUN floyd build

