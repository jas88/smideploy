SMIV	:= 5.1.3
RDMPV := 7.0.12

JARS	:= ctpanonymiser-1.0.0/CTPAnonymiser-portable-1.0.0.jar smi-nerd-v$(SMIV).jar
BINS	:=	smiinit
CXXFLAGS	:= -Wall -Wextra -O2 --std=c++11 -Iyaml-cpp/include

UNAME	:= $(shell uname)

.PHONY:	list clean distclean

all:	$(BINS)

minidocker: smi/smiinit smi/smiinit.sh smi/CTPAnonymiser-portable-1.0.0.jar smi/smi-nerd-v$(SMIV).jar smi/ctp-whitelist.script smi/eng.traineddata.gz
	mkdir -p smi
	touch smi/dummy.sh
	(cd smi-services-v$(SMIV)-linux-x64 && tar cf - .) | (cd smi && tar xf -)
	$(eval ctr1:=$(shell buildah from --name smidocker docker://docker.io/eclipse-temurin:11-jre))	
	tar c -f - smi/ | buildah run "$(ctr1)" sh -c "tar xof - && apt-get update && apt-get install -y libicu-dev"
	buildah config --cmd "/smi/smiinit.sh" "$(ctr1)"
	buildah commit "$(ctr1)" "smidocker"

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
	sed -i -e 's/LogsRoot: '\'\''/LogsRoot: '\''\/logs'\''/g' $@
	sed -i -e 's/Root: '\''\/tmp'\''/Root: '\''\/data'\''/g' $@
	sed -i -e 's/DataDirectory: '\'\''/DataDirectory: '\''\/data\/identifiablerules'\''/g' $@
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

smi/eng.traineddata.gz:
	curl -sL https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata | gzip -9 > $@

smi-services-v$(SMIV)-linux-x64/default.yaml:
	curl -sL https://github.com/SMI/SmiServices/releases/download/v$(SMIV)/smi-services-v$(SMIV)-linux-x64.tgz | tar xzf -
	sed -i -e 's:MappingTable'"'"':smi.MappingTable'"'"':' smi-services-v$(SMIV)-linux-x64/default.yaml
	sed -i -e 's/CTPAnonymiserOptions:/CTPAnonymiserOptions:\n    SRAnonTool: '\''\/smi\/dummy.sh'\''/' smi-services-v$(SMIV)-linux-x64/default.yaml


docker: smiinit $(JARS) $(HOME)/rdmp-cli/rdmp ctp-whitelist.script smi-services-v$(SMIV)-linux-x64/default.yaml
	touch smi-services-v$(SMIV)-linux-x64/dummy.sh
	$(eval ctr1:=$(shell buildah from docker://docker.io/debian:latest))
	buildah copy "$(ctr1)" smiinit /bin/
	buildah copy "$(ctr1)" $(HOME)/rdmp-cli /rdmp-cli
	buildah copy "$(ctr1)" $(JARS) ctp-whitelist.script smi-services-v$(SMIV)-linux-x64/ /smi
	./eqnames.pl < smi-services-v$(SMIV)-linux-x64/default.yaml | buildah run "$(ctr1)" -- bash 2>&1 | tee dockerbuild.log
	buildah config --cmd "/bin/smiinit -c /smi -f /smi.yaml" "$(ctr1)"
	buildah commit "$(ctr1)" "smifull"

$(HOME)/rdmp-cli/rdmp:	rdmp-cli-linux-x64.zip
	[ -e $@ ] || unzip -DD -d $(HOME)/rdmp-cli rdmp-cli-linux-x64.zip -x "Curation*" "zh-*"  "*\\Terminal.Gui.resources.dll"
	chmod +x $(HOME)/rdmp-cli/rdmp

rdmp-cli-linux-x64.zip:
	wget -q https://github.com/HicServices/RDMP/releases/download/v$(RDMPV)/rdmp-cli-linux-x64.zip

ctpanonymiser-v$(SMIV).zip:
	wget -q https://github.com/SMI/SmiServices/releases/download/v$(SMIV)/ctpanonymiser-v$(SMIV).zip

ctpanonymiser-1.0.0/CTPAnonymiser-portable-1.0.0.jar:	ctpanonymiser-v$(SMIV).zip
	[ -e $@ ] || unzip -DD $<
	
smi-nerd-v$(SMIV).jar:
	wget -q https://github.com/SMI/SmiServices/releases/download/v$(SMIV)/smi-nerd-v$(SMIV).jar

ctp-whitelist.script:
	wget -q https://raw.githubusercontent.com/SMI/SmiServices/v$(SMIV)/data/ctp/ctp-whitelist.script

smiinit:	smiinit.cpp yaml-cpp/build/libyaml-cpp.a
ifeq ($(UNAME), Darwin)
	$(CXX) $(CXXFLAGS) -o $@ $^
else
	$(CXX) -static -s $(CXXFLAGS) -o $@ $^
endif

yaml-cpp/build/libyaml-cpp.a:
	mkdir -p yaml-cpp/build
	cd yaml-cpp/build && cmake -DCMAKE_CXX_COMPILER_LAUNCHER=ccache .. && $(MAKE)

clean:
	$(RM) $(BINS) ctp-whitelist.script

distclean:	clean
	$(RM) -r yaml-cpp/build

.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
