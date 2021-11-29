FROM adoptopenjdk/openjdk11:debian-jre
RUN sh -c "apt-get update && apt-get install libicu63 && tar xof -"
ENTRYPOINT ["/smi/smiinit.sh"]
