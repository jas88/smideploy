FROM adoptopenjdk/openjdk11:debian-jre
RUN "apt-get update && apt-get install libicu67/stable && tar xf -"
ENTRYPOINT ["/smi/smiinit.sh"]
