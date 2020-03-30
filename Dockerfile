FROM golang:1.14-alpine AS build

ARG VERSION="unknown"
ARG TARGETPLATFORM

ENV GO_EXTLINK_ENABLED=0 \
    CGO_ENABLED=0

RUN apk add --no-cache git

WORKDIR /go/src/github.com/cloudflare/cloudflare-ingress-controller

COPY . ./

RUN go get github.com/golang/dep/cmd/dep && \
    dep ensure -v -vendor-only

RUN export GOOS=$(echo ${TARGETPLATFORM} | cut -d / -f1) && \
    export GOARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) && \
    GOARM=$(echo ${TARGETPLATFORM} | cut -d / -f3); export GOARM=${GOARM:1} && \
    go build -o /go/bin/argot \
    -ldflags="-w -s -extldflags -static -X main.version=${VERSION}" -tags netgo -installsuffix netgo \
    -v github.com/cloudflare/cloudflare-ingress-controller/cmd/argot

FROM alpine:3.9

RUN apk --no-cache add ca-certificates

COPY --from=build /go/bin/argot /bin/argot