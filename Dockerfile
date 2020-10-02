ARG JDK8_VERSION=jdk8u242-b08-alpine
ARG JMETER_VERSION=5.3
ARG TIMEZONE=Europe/Paris
ARG JMETER_HOME=/opt/apache-jmeter-${JMETER_VERSION}
ARG JMETER_BIN=${JMETER_HOME}/bin
ARG JMETER_PLUGINS_MANAGER_VERSION=1.4
ARG ULP_VIDEO_STREAMING_PLUGIN_VERSION=7.1.7
ARG CMDRUNNER_VERSION=2.2
ARG JSON_LIB_VERSION=2.4

FROM adoptopenjdk/openjdk8:${JDK8_VERSION} as BARE
LABEL maintainer="support@ubikloadpack.com"
STOPSIGNAL SIGKILL
ARG MIRROR=https://www-eu.apache.org/dist/jmeter/binaries
ARG ALPN_VERSION=8.1.13.v20181017
ARG JMETER_VERSION
ARG JMETER_HOME
ARG JMETER_BIN
ENV PATH=${JMETER_BIN}:$PATH
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh \
 && apk add --no-cache \
    curl \
    fontconfig \
    libxext \
    libxi \
    libxrender \
    libxtst \
    net-tools \
    shadow \
    su-exec \
    tcpdump  \
    ttf-dejavu \
 && cd /tmp/ \
 && curl --location --verbose --show-error --output apache-jmeter-${JMETER_VERSION}.tgz ${MIRROR}/apache-jmeter-${JMETER_VERSION}.tgz \
 && curl --location --verbose --show-error --output apache-jmeter-${JMETER_VERSION}.tgz.sha512 ${MIRROR}/apache-jmeter-${JMETER_VERSION}.tgz.sha512 \
 && sha512sum -c apache-jmeter-${JMETER_VERSION}.tgz.sha512 \
 && mkdir -p /opt/ \
 && tar x -z -f apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
 && rm -R -f apache* \
 && sed -i '/RUN_IN_DOCKER/s/^# //g' ${JMETER_BIN}/jmeter \
 && sed -i '/PrintGCDetails/s/^# /: "${/g' ${JMETER_BIN}/jmeter && sed -i '/PrintGCDetails/s/$/}"/g' ${JMETER_BIN}/jmeter \
 && chmod +x ${JMETER_HOME}/bin/*.sh \
 && jmeter --version \
 && rm -fr /tmp/* \
 && apk add --no-cache tzdata
 # Set the correct timezone for the container
ENV TZ ${TIMEZONE}
# Used to place gc logs in the /logs folder
ENV VERBOSE_GC -verbose:gc -Xloggc:/jmeter/logs/gc_%p_%t.log -XX:+PrintGCDetails -XX:+PrintGCCause -XX:+PrintTenuringDistribution -XX:+PrintHeapAtGC -XX:+PrintGCApplicationConcurrentTime -XX:+PrintAdaptiveSizePolicy -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCDateStamps
WORKDIR /jmeter
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["jmeter", "--?"]

FROM BARE
LABEL maintainer="support@ubikloadpack.com"
ARG JMETER_PLUGINS_MANAGER_VERSION
ARG ULP_VIDEO_STREAMING_PLUGIN_VERSION
ARG CMDRUNNER_VERSION
ARG JSON_LIB_VERSION
ARG JMETER_HOME
ARG JSON_LIB_FULL_VERSION=${JSON_LIB_VERSION}-jdk15
RUN cd /tmp/ \
 && curl --location --silent --show-error --output ${JMETER_HOME}/lib/ext/jmeter-plugins-manager-${JMETER_PLUGINS_MANAGER_VERSION}.jar http://search.maven.org/remotecontent?filepath=kg/apc/jmeter-plugins-manager/${JMETER_PLUGINS_MANAGER_VERSION}/jmeter-plugins-manager-${JMETER_PLUGINS_MANAGER_VERSION}.jar \
 && curl --location --silent --show-error --output ${JMETER_HOME}/lib/cmdrunner-${CMDRUNNER_VERSION}.jar http://search.maven.org/remotecontent?filepath=kg/apc/cmdrunner/${CMDRUNNER_VERSION}/cmdrunner-${CMDRUNNER_VERSION}.jar \
 && curl --location --silent --show-error --output ${JMETER_HOME}/lib/json-lib-${JSON_LIB_FULL_VERSION}.jar https://search.maven.org/remotecontent?filepath=net/sf/json-lib/json-lib/${JSON_LIB_VERSION}/json-lib-${JSON_LIB_FULL_VERSION}.jar \
 && java -cp ${JMETER_HOME}/lib/ext/jmeter-plugins-manager-${JMETER_PLUGINS_MANAGER_VERSION}.jar org.jmeterplugins.repository.PluginManagerCMDInstaller \
 && PluginsManagerCMD.sh install \
ulp-jmeter-videostreaming-plugin=${ULP_VIDEO_STREAMING_PLUGIN_VERSION},\
jpgc-autostop=0.1,\
jpgc-casutg=2.9,\
jpgc-cmd=2.2,\
jpgc-fifo=0.2,\
jpgc-functions=2.1,\
jpgc-tst=2.5\
 && jmeter --version \
 && PluginsManagerCMD.sh status \
 && chmod +x ${JMETER_HOME}/bin/*.sh \
 && rm -fr /tmp/*
