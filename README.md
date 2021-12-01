# SMIdeploy

Deployment tooling for the SMI image processing pipeline.

This assembles a Docker container combining all the many dependencies of the [SMI Services](https://github.com/SMI/SmiServices), plus the services themselves and the RDMP command line tool:

- Microsoft SQL Server (used by [RDMP](https://github.com/HicServices/RDMP) to hold 'management' data about the pipeline itself)
- MySQL (which holds the actual relational database tables with image metadata)
- MongoDB (holding all the extracted DICOM tag values)
- RabbitMQ (used to pass messages between microservices with queueing)
- Redis (some data caching)
- Java Runtime Environment (to run the [NER](https://nlp.stanford.edu/software/CRF-NER.shtml) and [CTP](http://mircwiki.rsna.org/index.php?title=MIRC_CTP) tools)
- Microsoft .Net 2.2 runtime, still required for now by the RDMP command line tool used to initialise the management database

The daemons above are all run under the supervision of the included `smiinit` tool, which reads a YAML configuration file telling it which commands to run; if any exits unexpectedly, it is automatically restarted to maintain service uptime. Upon receiving a `SIGTERM` signal, each worker process is sent the same signal to allow a graceful shutdown, followed by `SIGKILL` 3 seconds later.

## Intended usage

For development work on SMI itself: fetch the docker image, replace one or more microservices with your own version, start it and watch the results!

Any host system capable of running Linux-based Docker containers should suffice; for development/testing I am using the Buildah tools on Ubuntu: [install Buildah on Ubuntu 20.04](https://gist.github.com/sebastianwebber/2c1e9c7df97e05479f22a0d13c00aeca).

For example, to try replacing the [IsIdentifiable](https://github.com/SMI/SmiServices/tree/master/src/microservices/Microservices.IsIdentifiable) microservice with your own version:

`container=$(buildah from jas88/smi:latest)`
`buildah copy $container ~/SmiServices/obj/IsIdentifiable* /smi/`
`buildah run $container /bin/smiinit`

With the appropriate volume mappings for data persistence, this image could also be used to host your own replica of the real public SMI service, but production use will require further testing and documentation

## Future plans

- Run multiple copies of some microservices for higher throughput/scalability on powerful hardware
  - [EPCC](https://www.epcc.ed.ac.uk/) runs multiple copies across 3 machines with 128GB of RAM for the main Scottish Medical Imaging service with Public Health Scotland
- Persistence for non-development usage of this package and future deployment to HIC in Dundee
- Remove hard-coded SMI version number in default YAML config file generated during docker build

## Notes

- Newer releases of the SMI microservices can be incorporated by changing the SMIV variable, which currently defaults to v1.15.1 (the latest release at present)
- unzip -DD flag sets timestamp to current time instead of archive time, so Make logic works better.
- RDMP has to be run via "dotnet rdmp.dll" rather than "rdmp" directly, due to oddities in the legacy .Net runtime. Hopefully that won't apply for much longer...
- If building is interrupted, you may need to clean out /var/tmp/{buildah,storage}*
- Also clear out ~/.local periodically
- The rabbitmq-plugins tool consumes STDIN just to be "helpful". Hence needs a redirection when scripted. Sigh.

- If publishing:
  - Set DOCKERPW to Dockerhub token, DOCKERU to Dockerhub username and run "make publish"

## For leaf usage (as in HIC)

- Only the SMI microservices are contained in the Docker image produced
- Rabbit must be configured properly, along with an MS SQL server
- Configure the server addresses and credentials via the following Docker `secrets':
  - cscatalogue
  - csexport
  - csmapping
  - mongohost
  - mongopass
  - mongoport
  - mongouser
  - rabbithost
  - rabbitpass
  - rabbitport
  - rabbituser
- The first three are MS SQL connection strings; the Mongo and Rabbit ones should be self-explanatory.
- Rabbit will need the following queues/exchanges:
  - AccessionDirectoryExchange
  - AccessionDirectoryQueue
  - AnonymousImageExchange
  - AnonymousImageQueue
  - ControlExchange
  - DLQueue
  - ExtractFileAnonQueue
  - ExtractFileExchange
  - ExtractFileIdentQueue
  - ExtractedFileNoVerifyQueue
  - ExtractedFileStatusExchange
  - ExtractedFileToVerifyQueue
  - ExtractedFileVerifiedExchange
  - ExtractedFileVerifiedQueue
  - FatalLoggingExchange
  - FileCollectionInfoExchange
  - FileCollectionInfoQueue
  - IdentifiableImageExchange
  - IdentifiableImageQueue
  - IdentifiableSeriesExchange
  - MongoImageQueue
  - MongoSeriesQueue
  - RequestExchange
  - RequestInfoExchange
  - RequestInfoQueue
  - RequestQueue
  - TriggerUpdatesExchange
  - UpdateValuesQueue
- All exchanges should be type 'direct' except those containing the word 'control', which should be of type 'topic'. 
