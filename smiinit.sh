#!/bin/sh
set -e
export SMI_ROOT=/smi
export SMI_LOGS_ROOT=/logs
[ -d /data ] || echo "FATAL: Data volume missing!"
[ -d /data ] || exit
[ -d /logs ] || echo "WARNING: Log volume missing, discarding logs!"
mkdir -p /data/identifiablerules/tessdata
[ -e /data/identifiablerules/tessdata/eng.traineddata ] || zcat /smi/eng.traineddata.gz > /data/identifiablerules/tessdata/eng.traineddata
mkdir -p /logs
touch /logs/.writetest || echo "FATAL: Logs not writable"
touch /logs/.writetest || exit
cat << EOS > /smi/smi.yaml
jobs:
- "/opt/java/openjdk/bin/java -jar /smi/smi-nerd-v4.0.0.jar"
- "/opt/java/openjdk/bin/java -jar /smi/CTPAnonymiser-portable-1.0.0.jar -a /smi/ctp-whitelist.script -y /smi/smi.yaml"
- "/smi/smi dicom-relational-mapper -y /smi/smi.yaml"
- "/smi/smi is-identifiable service -y /smi/smi.yaml"
- "/smi/smi cohort-extractor -y /smi/smi.yaml"
- "/smi/smi dicom-tag-reader -y /smi/smi.yaml"
- "/smi/smi mongodb-populator -y /smi/smi.yaml"
- "/smi/smi cohort-packager -y /smi/smi.yaml"
- "/smi/smi file-copier -y /smi/smi.yaml"
- "/smi/smi identifier-mapper -y /smi/smi.yaml"
- "/smi/smi update-values -y /smi/smi.yaml"
