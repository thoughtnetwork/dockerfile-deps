FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gpg wget

ENV DASH_VERSION 0.18.0
ENV DASH_URL https://github.com/thoughtnetwork/thought-wallet/raw/master/linux/thought-0.18.0/thoughtcore-0.18.0-x86_64-pc-linux-gnu.tar.gz
ENV DASH_SHA256 c28881104ef7b3bdede7eb2b231b076a6e69213948695b4ec79ccb5621c04d97
ENV DASH_ASC_URL https://github.com/thoughtpay/thought/releases/download/v0.14.0.1/SHA256SUMS.asc
ENV DASH_PGP_KEY 63a96b406102e091

# install thought binaries
RUN set -ex \
	&& cd /tmp \
	&& wget -qO thought.tar.gz "$DASH_URL" \
#	&& echo "$DASH_SHA256 thought.tar.gz" | sha256sum -c - \
#	&& gpg --keyserver keyserver.ubuntu.com --recv-keys "$DASH_PGP_KEY" \
#	&& wget -qO thought.asc "$DASH_ASC_URL" \
#	&& gpg --verify thought.asc \
	&& mkdir bin \
	&& tar -xzvf thought.tar.gz -C /tmp/bin --strip-components=2 "thoughtcore-$DASH_VERSION/bin/thought-cli" "thoughtcore-$DASH_VERSION/bin/thoughtd" \
	&& cd bin \
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64" \
	&& echo "0b843df6d86e270c5b0f5cbd3c326a04e18f4b7f9b8457fa497b0454c4b138d7 gosu" | sha256sum -c -

FROM debian:stretch-slim
COPY --from=builder "/tmp/bin" /usr/local/bin

RUN chmod +x /usr/local/bin/gosu && groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin

# create data directory
ENV BITCOIN_DATA /data
RUN mkdir "$BITCOIN_DATA" \
	&& chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.thoughtcore \
	&& chown -h bitcoin:bitcoin /home/bitcoin/.thoughtcore

VOLUME /data

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 9998 9999 19998 19999
CMD ["thoughtd"]
