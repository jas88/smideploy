set -e
apt-get update
apt-get install -y --no-install-recommends wget software-properties-common gnupg2

## Team RabbitMQ's main signing key
apt-key adv --keyserver "hkps://keys.openpgp.org" --recv-keys "0x0A9AF2115F4687BD29803A206B73A36E6026DFCA"
## Cloudsmith: modern Erlang repository
wget -qO- https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/gpg.E495BB49CC4BBE5B.key | apt-key add -
## Cloudsmith: RabbitMQ repository
wget -qO- https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/gpg.9F4587F226208342.key | apt-key add -

apt-key add <<EOK
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.7 (GNU/Linux)

mQENBFYxWIwBCADAKoZhZlJxGNGWzqV+1OG1xiQeoowKhssGAKvd+buXCGISZJwT
LXZqIcIiLP7pqdcZWtE9bSc7yBY2MalDp9Liu0KekywQ6VVX1T72NPf5Ev6x6DLV
7aVWsCzUAF+eb7DC9fPuFLEdxmOEYoPjzrQ7cCnSV4JQxAqhU4T6OjbvRazGl3ag
OeizPXmRljMtUUttHQZnRhtlzkmwIrUivbfFPD+fEoHJ1+uIdfOzZX8/oKHKLe2j
H632kvsNzJFlROVvGLYAk2WRcLu+RjjggixhwiB+Mu/A8Tf4V6b+YppS44q8EvVr
M+QvY7LNSOffSO6Slsy9oisGTdfE39nC7pVRABEBAAG0N01pY3Jvc29mdCAoUmVs
ZWFzZSBzaWduaW5nKSA8Z3Bnc2VjdXJpdHlAbWljcm9zb2Z0LmNvbT6JATUEEwEC
AB8FAlYxWIwCGwMGCwkIBwMCBBUCCAMDFgIBAh4BAheAAAoJEOs+lK2+EinPGpsH
/32vKy29Hg51H9dfFJMx0/a/F+5vKeCeVqimvyTM04C+XENNuSbYZ3eRPHGHFLqe
MNGxsfb7C7ZxEeW7J/vSzRgHxm7ZvESisUYRFq2sgkJ+HFERNrqfci45bdhmrUsy
7SWw9ybxdFOkuQoyKD3tBmiGfONQMlBaOMWdAsic965rvJsd5zYaZZFI1UwTkFXV
KJt3bp3Ngn1vEYXwijGTa+FXz6GLHueJwF0I7ug34DgUkAFvAs8Hacr2DRYxL5RJ
XdNgj4Jd2/g6T9InmWT0hASljur+dJnzNiNCkbn9KbX7J/qK1IbR8y560yRmFsU+
NdCFTW7wY0Fb1fWJ+/KTsC4=
=J6gs
-----END PGP PUBLIC KEY BLOCK-----
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=tsX2
-----END PGP PUBLIC KEY BLOCK-----
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQINBFzteqwBEADSirbLWsjgkQmdWr06jXPN8049MCqXQIZ2ovy9uJPyLkHgOCta
8dmX+8Fkk5yNOLScjB1HUGJxAWJG+AhldW1xQGeo6loDfTW1mlfetq/zpW7CKbUp
qve9eYYulneAy/81M/UoUZSzHqj6XY39wzJCH20H+Qx3WwcqXgSU7fSFXyJ4EBYs
kWybbrAra5v29LUTBd7OvvS+Swovdh4T31YijUOUUL/gJkBI9UneVyV7/8DdUoVJ
a8ym2pZ6ALy+GZrWBHcCKD/rQjEkXJnDglu+FSUI50SzaC9YX31TTzEMJijiPi6I
MIZJMXLH7GpCIDcvyrLWIRYVJAQRoYJB4rmp42HTyed4eg4RnSiFrxVV5xQaDnSl
/8zSOdVMBVewp8ipv34VeRXgNTgRkhA2JmL+KlALMkPo7MbRkJF01DiOOsIdz3Iu
43oYg3QYmqxZI6kZNtXpUMnJeuRmMQJJN8yc9ZdOA9Ll2TTcIql8XEsjGcM7IWM9
CP6zGwCcbrv72Ka+h/bGaLpwLbpkr5I8PjjSECn9fBcgnVX6HfKH7u3y11+Va1nh
a8ZEE1TuOqRxnVDQ+K4iwaZFgFYsBMKo2ghoU2ZbZxu14vs6Eksn6UFsm8DpPwfy
jtLtdje8jrbYAqAy5zIMLoW+I6Rb5sU3Olh9nI7NW4T5qQeemBcuRAwB4QARAQAB
tDdNb25nb0RCIDQuNCBSZWxlYXNlIFNpZ25pbmcgS2V5IDxwYWNrYWdpbmdAbW9u
Z29kYi5jb20+iQI+BBMBAgAoBQJc7XqsAhsDBQkJZgGABgsJCAcDAgYVCAIJCgsE
FgIDAQIeAQIXgAAKCRBlZAjjkM+x9SKmD/9BzdjFAgBPPkUnD5pJQgsBQKUEkDsu
cht6Q0Y4M635K7okpqJvXtZV5Mo+ajWZjUeHn4wPdVgzF2ItwVLRjjak3tIZfe3+
ME5Y27Aej3LeqQC3Q5g6SnpeZwVEhWzU35CnyhQecP4AhDG3FO0gKUn3GkEgmsd6
rnXAQLEw3VUYO8boxqBF3zjmFLIIaODYNmO1bLddJgvZlefUC62lWBBUs6Z7PBnl
q7qBQFhz9qV9zXZwCT2/vgGLg5JcwVdcJXwAsQSr1WCVd7Y79+JcA7BZiSg9FAQd
4t2dCkkctoUKgXsAH5fPwErGNj5L6iUnhFODPvdDJ7l35UcIZ2h74lqfEh+jh8eo
UgxkcI2y2FY/lPapcPPKe0FHzCxG2U/NRdM+sqrIfp9+s88Bj+Eub7OhW4dF3AlL
bh/BGHL9R8xAJRDLv8v7nsKkZWUnJaskeDFCKX3rjcTyTRWTG7EuMCmCn0Ou1hKc
R3ECvIq0pVfVh+qk0hu+A5Dvj6k3QDcTfse+KfSAJkYvRKiuRuq5KgYcX3YSzL6K
aZitMyu18XsQxKavpIGzaDhWyrVAig3XXF//zxowYVwuOikr5czgqizu87cqjpyn
S0vVG4Q3+LswH4xVTn3UWadY/9FkM167ecouu4g3op29VDi7hCKsMeFvFP6OOIls
G4vQ/QbzucK77Q==
=eD3N
-----END PGP PUBLIC KEY BLOCK-----
EOK
add-apt-repository -u "deb [arch=amd64] https://packages.microsoft.com/ubuntu/18.04/prod bionic main"
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" > /etc/apt/sources.list.d/mongodb-org-4.4.list

## Add apt repositories maintained by Team RabbitMQ
tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
## Provides modern Erlang/OTP releases
##
deb https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/deb/ubuntu bionic main
deb-src https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/deb/ubuntu bionic main

## Provides RabbitMQ
##
deb https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/deb/ubuntu bionic main
deb-src https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/deb/ubuntu bionic main
EOF

add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/ubuntu/18.04/prod bionic main"
add-apt-repository -u "deb [arch=amd64] https://packages.microsoft.com/ubuntu/18.04/mssql-server-2019 bionic main"
apt-get update
ACCEPT_EULA=Y apt-get install -y --no-install-recommends libtinfo-dev libtinfo6 rabbitmq-server mssql-tools mariadb-server default-jre-headless mongodb-org redis-server
apt-get install -y --no-install-recommends mssql-server
MSSQL_SA_PASSWORD="YourStrong\!Passw0rd" /opt/mssql/bin/sqlservr --pid 3 --setup --reset-sa-password --accept-eula

/opt/mssql/bin/sqlservr &
sleep 10

# Disable irrelenvant .Net L16n to avoid extra dependencies or a coredump from RDMP
cat > /rdmp-cli/rdmp.runtimeconfig.json <<EOJ
{
    "runtimeOptions": {
        "configProperties": {
            "System.Globalization.Invariant": true
        },
	    "tfm": "net5.0",
	    "includedFrameworks": [
	      {
	        "name": "Microsoft.NETCore.App",
	        "version": "5.0.3"
	      }
	    ]
    }
}
EOJ
./rdmp-cli/rdmp install localhost TEST_ -u sa -p "YourStrong\!Passw0rd"
kill -TERM `jobs -p`

mkdir -p /data/db
echo -e '\nreplication:\n  replSetName: rs0' >> /etc/mongodb.conf
mongod -f /etc/mongodb.conf &
sleep 10
mongo --eval 'rs.initiate()'
kill -TERM `jobs -p`

echo "NODENAME=rabbit@localhost" > /etc/rabbitmq/rabbitmq-env.conf
mkdir -p /var/lib/rabbitmq
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq
rabbitmq-server &
sleep 15
rabbitmq-plugins enable rabbitmq_management < /dev/null
wget -O/bin/rabbitmqadmin http://127.0.0.1:15672/cli/rabbitmqadmin
chmod +x /bin/rabbitmqadmin
# RABBITGOESHERE
kill -TERM `jobs -p`

wget -O/smi/ctp.script https://github.com/SMI/SmiServices/blob/master/data/ctp/ctp-whitelist.script
cat > /smi.yaml <<EOY
jobs:
- "/opt/mssql/bin/sqlservr"
- "/usr/bin/mongod"
- "/usr/bin/redis-server"
- "/usr/sbin/mysqld"
- "/usr/sbin/rabbitmq-server"
- "wait"
- "/usr/bin/java -jar /smi/smi-nerd-v1.15.1.jar"
- "/usr/bin/java -jar /smi/CTPAnonymiser-portable-1.0.0.jar -a /smi/ctp.script -y /smi.yaml"
- "/smi/DicomRelationalMapper -y /smi.yaml"
- "/smi/IsIdentifiable -y /smi.yaml"
- "/smi/CohortExtractor -y /smi.yaml"
- "/smi/DicomTagReader -y /smi.yaml"
- "/smi/MongoDbPopulator -y /smi.yaml"
- "/smi/CohortPackager -y /smi.yaml"
- "/smi/FileCopier -y /smi.yaml"
- "/smi/DicomReprocessor -y /smi.yaml"
- "/smi/IdentifierMapper -y /smi.yaml"
- "/smi/DeadLetterReprocessor -y /smi.yaml"
- "/smi/UpdateValues -y /smi.yaml"

EOY
sed -e 's/c:\\temp/\/tmp/gi' /smi/default.yaml >> /smi.yaml
