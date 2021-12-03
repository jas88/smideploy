#!/bin/sh
set -e
cat << EOS > /smi/smi.yaml
jobs:
- "/usr/bin/java -jar /smi/smi-nerd-v3.0.2.jar"
- "/usr/bin/java -jar /smi/CTPAnonymiser-portable-1.0.0.jar -a /smi/ctp-whitelist.script -y /smi/smi.yaml"
- "/smi/smi dicom-relational-mapper -y /smi/smi.yaml"
- "/smi/smi is-identifiable service -y /smi/smi.yaml"
- "/smi/smi cohort-extractor -y /smi/smi.yaml"
- "/smi/smi dicom-tag-reader -y /smi/smi.yaml"
- "/smi/smi mongodb-populator -y /smi/smi.yaml"
- "/smi/smi cohort-packager -y /smi/smi.yaml"
- "/smi/smi file-copier -y /smi/smi.yaml"
- "/smi/smi identifier-mapper -y /smi/smi.yaml"
- "/smi/smi update-values -y /smi/smi.yaml"
