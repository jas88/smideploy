FROM adoptopenjdk/openjdk11:debian-jre
RUN sh -c "tar xof - && apt-get update && apt-get install libicu63"
ENTRYPOINT ["/smi/smiinit.sh"]
