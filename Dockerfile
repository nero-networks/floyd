FROM node:13

# put the floyd command into $PATH
ENV PATH="/opt/floyd/bin:${PATH}"

# prepare NODE_PATH so floyd apps find floyd/node_modules/something
ENV NODE_PATH=/opt/floyd/node_modules

# copy everything from floyd to /opt/floyd.
COPY . /opt/floyd

# run initial build. takes care of npm
RUN cd /opt/floyd && floyd build && mkdir /node_modules && cd /node_modules && ln -s /opt/floyd && cd / &&  floyd create app && useradd -d /app -U app && chown -R app:app /app

