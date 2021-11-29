FROM adoptopenjdk/openjdk11:debian-jre
RUN "apt-get update && apt-get install libicu67/stable && tar xf -o -"
ENTRYPOINT ["/smi/smiinit.sh"]
