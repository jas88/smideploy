SMIV	:= 4.0.0

JARS	:= ctpanonymiser-1.0.0/CTPAnonymiser-portable-1.0.0.jar smi-nerd-v$(SMIV).jar
BINS	:=	smiinit
CXXFLAGS	:= -Wall -Wextra -O2 --std=c++11 -Iyaml-cpp/include

UNAME	:= $(shell uname)

.PHONY:	list clean distclean

all:	$(BINS)

publish:	docker
	echo $(DOCKERPW) | buildah login -u $(DOCKERU) --password-stdin docker.io
	buildah commit "$(ctr1)" "jas88/smi"
	buildah push jas88/smi docker://docker.io/jas88/smi:latest

minidocker: smi/smiinit smi/smiinit.sh smi/CTPAnonymiser-portable-1.0.0.jar
	mkdir -p smi
	touch smi/dummy.sh
	(cd smi-services-v4.0.0-linux-x64;tar cf - .) | (cd smi ; tar xf -)
	tar c --uid 0 --gid 0 -f - smi/ | buildah build -t smidocker

smi/smiinit.sh:  smi-services-v$(SMIV)-linux-x64/default.yaml
	mkdir -p smi
	cp smiinit.sh $@
	sed -e 's/c:\\temp/\/tmp/gi' $< | tail -n +2 >> $@
	sed -i -e 's/TEST.//g' $@
	sed -i -e 's/RabbitMqUserName: '\''guest'\''/RabbitMqUserName: '\''\$$(<\/run\/secrets\/rabbituser)'\''/g' $@
	sed -i -e 's/RabbitMqHostName: '\''localhost'\''/RabbitMqHostName: '\''\$$(<\/run\/secrets\/rabbithost)'\''/g' $@
	sed -i -e 's/RabbitMqHostPort: 5672/RabbitMqHostPort: \$$(<\/run\/secrets\/rabbitport)/g' $@
	sed -i -e 's/RabbitMqPassword: '\''guest'\''/RabbitMqPassword: '\''\$$(<\/run\/secrets\/rabbitpass)'\''/g' $@
	sed -i -e 's/HostName: '\''localhost'\''/HostName: '\''\$$(<\/run\/secrets\/mongohost)'\''/g' $@
	sed -i -e 's/UserName: '\'''\''/UserName: '\''\$$(<\/run\/secrets\/mongouser)'\''/g' $@
	sed -i -e 's/Password: '\'''\''/Password: '\''\$$(<\/run\/secrets\/mongopass)'\''/g' $@
	sed -i -e 's/Port: 27017/Port: \$$(<\/run\/secrets\/mongoport)/g' $@
	sed -i -e 's/CatalogueConnectionString: '\''[^'\'']*'\''/CatalogueConnectionString: '\''\$$(<\/run\/secrets\/cscatalogue)'\''/g' $@
	sed -i -e 's/DataExportConnectionString: '\''[^'\'']*'\''/DataExportConnectionString: '\''\$$(<\/run\/secrets\/csexport)'\''/g' $@
	sed -i -e 's/MappingConnectionString: '\''[^'\'']*'\''/MappingConnectionString: '\''\$$(<\/run\/secrets\/csmapping)'\''/g' $@
	echo EOS >> $@
	echo exec /smi/smiinit -c /smi -f /smi/smi.yaml >> $@
	chmod +x $@
	
smi/smiinit:	smiinit
	mkdir -p smi
	cp $< $@

smi/CTPAnonymiser-portable-1.0.0.jar:	ctpanonymiser-1.0.0/CTPAnonymiser-portable-1.0.0.jar
	mkdir -p smi
	ln -f $< $@

smi/smi-nerd-v$(SMIV).jar: smi-nerd-v$(SMIV).jar
	mkdir -p smi
	ln -f $< $@

smi/ctp-whitelist.script: ctp-whitelist.script
	mkdir -p smi
	ln -f $< $@

smi-services-v$(SMIV)-linux-x64/default.yaml:
	curl -L https://github.com/SMI/SmiServices/releases/download/v$(SMIV)/smi-services-v$(SMIV)-linux-x64.tgz | tar xzf -
	sed -i -e 's:MappingTable'"'"':smi.MappingTable'"'"':' smi-services-v$(SMIV)-linux-x64/default.yaml
	sed -i -e 's/CTPAnonymiserOptions:/CTPAnonymiserOptions:\n    SRAnonTool: '\''\/smi\/dummy.sh'\''/' smi-services-v$(SMIV)-linux-x64/default.yaml


docker: smiinit $(JARS) $(HOME)/rdmp-cli/rdmp ctp-whitelist.script smi-services-v$(SMIV)-linux-x64/default.yaml
	touch smi-services-v$(SMIV)-linux-x64/dummy.sh
	$(eval ctr1:=$(shell buildah from docker://docker.io/debian:latest))
	buildah copy "$(ctr1)" smiinit /bin/
	buildah copy "$(ctr1)" $(HOME)/rdmp-cli /rdmp-cli
	buildah copy "$(ctr1)" $(JARS) ctp-whitelist.script smi-services-v$(SMIV)-linux-x64/ /smi
	./eqnames.pl < smi-services-v3.0.2-linux-x64/default.yaml | buildah run "$(ctr1)" -- bash 2>&1 | tee dockerbuild.log
	buildah config --cmd "/bin/smiinit -c /smi -f /smi.yaml" "$(ctr1)"

$(HOME)/rdmp-cli/rdmp:	rdmp-cli-linux-x64.zip
	[ -e $@ ] || unzip -DD -d $(HOME)/rdmp-cli rdmp-cli-linux-x64.zip -x "Curation*" "zh-*"
	chmod +x $(HOME)/rdmp-cli/rdmp

rdmp-cli-linux-x64.zip:
	wget https://github.com/HicServices/RDMP/releases/download/v5.0.0/rdmp-cli-linux-x64.zip

ctpanonymiser-$(SMIV).zip:
	wget https://github.com/SMI/SmiServices/releases/download/v$(SMIV)/ctpanonymiser-v$(SMIV).zip

ctpanonymiser-1.0.0/CTPAnonymiser-portable-1.0.0.jar:	ctpanonymiser-v$(SMIV).zip
	[ -e $@ ] || unzip -DD $<
	
smi-nerd-v$(SMIV).jar:
	wget https://github.com/SMI/SmiServices/releases/download/v$(SMIV)/smi-nerd-v$(SMIV).jar

ctp-whitelist.script:
	wget https://raw.githubusercontent.com/SMI/SmiServices/v$(SMIV)/data/ctp/ctp-whitelist.script

smiinit:	smiinit.cpp yaml-cpp/build/libyaml-cpp.a
ifeq ($(UNAME), Darwin)
	$(CXX) $(CXXFLAGS) -o $@ $^
else
	$(CXX) -static -s $(CXXFLAGS) -o $@ $^
endif

yaml-cpp/build/libyaml-cpp.a:
	mkdir -p yaml-cpp/build
	cd yaml-cpp/build && cmake .. && $(MAKE)

clean:
	$(RM) $(BINS) ctp-whitelist.script

distclean:	clean
	$(RM) -r yaml-cpp/build

.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
