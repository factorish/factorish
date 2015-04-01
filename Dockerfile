FROM gliderlabs/alpine

RUN apk --update add nodejs

WORKDIR /app

CMD node plugin/notes-server

EXPOSE 8000

ADD . /app

RUN npm install

