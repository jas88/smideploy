# smideploy
Deployment tooling for the SMI image processing pipeline


## Notes

- unzip -DD flag sets timestamp to current time instead of archive time, so Make logic works better.
- RDMP has to be run via "dotnet rdmp.dll" rather than "rdmp" directly, due to oddities in the legacy .Net runtime. Hopefully that won't apply for much longer...
- If building is interrupted, you may need to clean out /var/tmp/{buildah,storage}*
- Also clear out ~/.local periodically
- The rabbitmq-plugins tool consumes STDIN just to be "helpful". Hence needs a redirection when scripted. Sigh.

- If publishing:
  - Set DOCKERPW to Dockerhub token, DOCKERU to Dockerhub username and run "make publish"