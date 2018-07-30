FROM jenkins/jenkins:2.121.1

USER root

RUN ln -s /usr/local/bin/install-plugins.sh /usr/bin/install-plugins && \
    install-plugins ssh-slaves && \
    install-plugins email-ext && \
    install-plugins mailer && \
    install-plugins slack && \
    install-plugins htmlpublisher && \
    install-plugins greenballs && \
    install-plugins simple-theme-plugin && \
    install-plugins kubernetes && \
    install-plugins git && \
    install-plugins ansicolor && \
    install-plugins groovy && \
    install-plugins workflow-aggregator && \
    install-plugins blueocean

RUN apt-get update && \
    apt-get install -y maven
