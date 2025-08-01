# This is Makefile for the coco-shelf.
#
#        https://github.com/strickyak/coco-shelf
#
# The coco-shelf helps you build packages associated with Nitros9
# (especially strick's frobio networking packages)
# in a standard and (mostly) repeatable way on modern Linux machines.

# You can edit version numbers in here, to upgrade to newer packages:
include conf.mk

# Keeping go.work up-to-date really makes golang happy.
CREATE_GO_WORK = set -x; \
    rm -f go.work && \
    go work init $$( find [a-z]*/ -name go.mod | grep -v /go/ | grep -v /pkg/ | sed 's;/go.mod;;') && \
    cat -n go.work && \
    mkdir -p bin && \
    true
    #??# cp -fv scripts/go-easy.sh bin/go && \
    #??# chmod +x bin/go
    #??#

PICO_ENV = PICO_EXAMPLES_PATH=/dev/null PICO_SDK_PATH=$S/pico-sdk

all: all-fetches frobio.done FoenixMgr.done whippets.done copico-bonobo.done

go.work: _FORCE_
	$(CREATE_GO_WORK)

########
##
##    run-*   targets

run-lemma: frobio.done
	make -C build-frobio run-lemma

f256-flash: run-f256jr-flash
	: "f256-flash" is the old target name.  "run-f256-flash" is the new target name.
run-f256-flash: FoenixMgr.done
	NITROS9DIR=`pwd`/nitros9 make -C nitros9/level1/f256/feu flash
run-f256jr-flash: FoenixMgr.done
	NITROS9DIR=`pwd`/nitros9 make -C nitros9/level1/f256/feu flash_f256jr
run-f256k-flash: FoenixMgr.done
	NITROS9DIR=`pwd`/nitros9 make -C nitros9/level1/f256/feu flash_f256k

############################################################################

all-eou.got: eou-h6309.got eou-m6809.got eou-101-h6309.got eou-101-m6809.got
	date > $@

eou-h6309.got: inputs/eou-h6309.zip
	B=$(basename $@); rm -rf $$B
	B=$(basename $@); mkdir -p $$B
	B=$(basename $@); cd $$B && unzip ../$<
	date > $@
eou-m6809.got: inputs/eou-m6809.zip
	B=$(basename $@); rm -rf $$B
	B=$(basename $@); mkdir -p $$B
	B=$(basename $@); cd $$B && unzip ../$<
	date > $@
eou-101-h6309.got: inputs/eou-101-h6309.zip
	B=$(basename $@); rm -rf $$B
	B=$(basename $@); mkdir -p $$B
	B=$(basename $@); cd $$B && unzip ../$<
	date > $@
eou-101-m6809.got: inputs/eou-101-m6809.zip
	B=$(basename $@); rm -rf $$B
	B=$(basename $@); mkdir -p $$B
	B=$(basename $@); cd $$B && unzip ../$<
	date > $@

lwtools.got: inputs/$(COCO_LWTOOLS_TARBALL)
	set -x; test -d lwtools || { tar -xzf inputs/$(COCO_LWTOOLS_TARBALL) && mv -v $(COCO_LWTOOLS_VERSION) lwtools ; }
	date > $@
cmoc.got: inputs/$(COCO_CMOC_TARBALL)
	set -x; test -d cmoc || { tar -xzf inputs/$(COCO_CMOC_TARBALL) && mv -v $(COCO_CMOC_VERSION) cmoc ; }
	date > $@
gccretro.got: inputs/$(COCO_GCCRETRO_TARBALL) lwtools.done inputs/gcc-config-guess
	set -x; test -d gccretro || { tar -xjf inputs/$(COCO_GCCRETRO_TARBALL) && mv -v $(COCO_GCCRETRO_VERSION) gccretro && \
	      (cd gccretro && patch -p1 < ../lwtools/extra/gcc6809lw-4.6.4-9.patch) ; }
	mkdir -p bin
	cp -fv inputs/gcc-config-guess "gccretro/config.guess"
	cp -fv inputs/gcc-config-guess "gccretro/libjava/libltdl/config.guess"
	cp -fv inputs/gcc-config-guess "gccretro/libjava/classpath/config.guess"
	cp -fv lwtools/extra/as bin/m6809-unknown-as
	cp -fv lwtools/extra/ld bin/m6809-unknown-ld
	cp -fv lwtools/extra/ar bin/m6809-unknown-ar
	set -x; ln -sfv /bin/true bin/m6809-unknown-ranlib
	set -x; ln -sfv /bin/true bin/makeinfo
	date > $@

pico-sdk.got: inputs/$(COCO_PICOSDK_TARBALL)
	set -x; test -d pico-sdk || { tar -xzf inputs/$(COCO_PICOSDK_TARBALL) ; }
	date > "$@"

picotool.got: inputs/$(COCO_PICOTOOL_TARBALL)
	set -x; test -d picotool || { tar -xzf inputs/$(COCO_PICOTOOL_TARBALL) ; }
	date > "$@"

############################################################################

tfr9.done: tfr9.got lwtools.done nitros9.done turbos.done pico-sdk.got
	make -C tfr9/v3
	date > "$@"

turbos.done: turbos.got tfr9.got lwtools.done
	make -C turbos/ports/turbo9sim TURBOSDIR=$S/turbos
	date > "$@"

copico-bonobo.done: copico-bonobo.got picotool.done pico-sdk.got nekotos.done
	make -C copico-bonobo/v2.4/tether all install
	: DISABLE : rm -rf copico-bonobo/v2.4/firmware/build-c/*
	mkdir -p copico-bonobo/v2.4/firmware/build-c/ lib
	make -C copico-bonobo/v2.4/firmware
	: #cd copico-bonobo/v2.4/firmware/build-c/ && \
	: #    $(PICO_ENV) cmake ../c/
	: #$(PICO_ENV) make -j4 -C copico-bonobo/v2.4/firmware/build-c/
	: we dont really have a better place to copy it to, yet :
	cp -fv copico-bonobo/v2.4/firmware/build-c/bonobo.uf2 lib/
	date > "$@"

nekotos.done: nekotos.got gccretro.done frobio.done
	make -C nekotos
	date > "$@"

picotool.done: picotool.got pico-sdk.got
	rm -rf build-picotool
	mkdir -p build-picotool bin
	cd build-picotool && \
        $(PICO_ENV) cmake ../picotool \
           -D'PICO_SDK_PATH'="$S/pico-sdk" \
           -DCMAKE_INSTALL_PREFIX=$S/lib -DPICOTOOL_FLAT_INSTALL=1
	cd build-picotool && \
        $(PICO_ENV) cmake --build .
	cd build-picotool && \
        $(PICO_ENV) cmake --install .
	cp -fv build-picotool/picotool bin/
	date > "$@"

whippets.done: whippets.got frobio.done gomar.got
	make -C whippets
	date > "$@"
ifdef KEEP
	: keeping /tmp/for-hasty-* files.
else
	rm -rf /tmp/for-hasty-*
	make -C whippets clean
endif

frobio.done: frobio.got cmoc.done nitros9.done gccretro.done all-eou.got nekotos.got
	ln -sfv m6809-unknown-$(COCO_GCCRETRO_VERSION) bin/gcc6809
	mkdir -p build-frobio
	cd build-frobio && ../frobio/frob3/configure --nitros9="$(SHELF)/nitros9"
	make -C build-frobio
	date > frobio.done

FoenixMgr.done: FoenixMgr.got nitros9.done
	echo 'set -x; python3 "$$@"' > bin/python && chmod +x bin/python
	set -x; for x in FoenixMgr/tools/sh/*; do y=$$(basename $$x); ( sh gen-sh-prelude.sh ; cat $$x ) >bin/$$y; chmod +x bin/$$y; done
	date > FoenixMgr.done

toolshed.done: toolshed.got lwtools.done
	cp -v scripts/md5.sh bin/md5
	chmod +x bin/md5
	make -C toolshed -C build/unix DESTDIR="$$SHELF" all
	make -C toolshed -C build/unix DESTDIR="$$SHELF" install
	( cd bin && ln -sfv ../usr/bin/* . )
	make -C toolshed -C cocoroms DESTDIR="$$SHELF"
	make -C toolshed -C hdbdos DESTDIR="$$SHELF"
	date > toolshed.done

nitros9.done: nitros9.got toolshed.done lwtools.done
	NITROS9DIR=$(SHELF)/nitros9 make -C nitros9 -C lib
	NITROS9DIR=$(SHELF)/nitros9 make -C nitros9 PORTS=coco1 dsk
	NITROS9DIR=$(SHELF)/nitros9 make -C nitros9 PORTS=coco1_6309 dsk
	NITROS9DIR=$(SHELF)/nitros9 make -C nitros9 PORTS=coco3 dsk
	NITROS9DIR=$(SHELF)/nitros9 make -C nitros9 PORTS=coco3_6309 dsk
	NITROS9DIR=$(SHELF)/nitros9 make -C nitros9 PORTS=f256 dsk
	NITROS9DIR=$(SHELF)/nitros9 make -C nitros9 -C level1/f256/feu
	date > nitros9.done

lwtools.done: lwtools.got
	make -C lwtools PREFIX="$(SHELF)" all
	make -C lwtools PREFIX="$(SHELF)" install
	set -x; test -z "$$(find bin -name lwasm  -size +10k)" || ( \
        mv -fv bin/lwasm bin/lwasm.orig && \
        cp -fv scripts/lwasm-with-listing.sh bin/lwasm && \
        chmod +x bin/lwasm \
      )
	date > lwtools.done

cmoc.done: cmoc.got lwtools.done
	cd cmoc && ./configure --prefix="$(SHELF)"
	make -C cmoc PREFIX="$(SHELF)" all
	make -C cmoc PREFIX="$(SHELF)" install
	date > cmoc.done

gccretro.done: gccretro.got lwtools.done
	echo PATH -- $$PATH -- PATH
	which makeinfo
	mkdir -p build-gccretro
	SHELF=`pwd`; cd build-gccretro && PATH="$(PATH)" ../gccretro/configure \
        --prefix="$$SHELF" \
        --enable-languages=c \
        --target=m6809-unknown \
        --disable-libada \
        --program-prefix=m6809-unknown- \
        --enable-obsolete \
        --disable-threads \
        --disable-nls \
        --disable-libssp \
        --with-as="$$SHELF/bin/m6809-unknown-as" \
        --with-ld="$$SHELF/bin/m6809-unknown-ld" \
        --with-ar="$$SHELF/bin/m6809-unknown-ar" \
        ##
	make -j2 -C build-gccretro MAKEINFO=true all-gcc
	cd build-gccretro && echo "// This is a kludge, not the real limits.h" > gcc/include-fixed/limits.h
	make -j2 -C build-gccretro MAKEINFO=true all-target-libgcc
	make -C build-gccretro MAKEINFO=true install-gcc
	make -C build-gccretro MAKEINFO=true install-target-libgcc
	:
	rm -f bin/gcc6809
	ln -sfv m6809-unknown-$(COCO_GCCRETRO_VERSION) bin/gcc6809
	:
	date > gccretro.done

############################################################################

all-fetches: all-inputs all-gits

all-gits: \
  FoenixMgr.got \
  toolshed.got \
  nitros9.got \
  gomar.got \
  whippets.got \
  frobio.got \
  nekotos.got \
  copico-bonobo.got \
  ##

FoenixMgr.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_FOENIXMGR_REPO) $$B
	date > $@
toolshed.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_TOOLSHED_REPO) $$B
	date > $@
nitros9.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_NITROS9_REPO) $$B
	date > $@
gomar.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_GOMAR_REPO) $$B
	$(CREATE_GO_WORK)
	date > $@
frobio.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_FROBIO_REPO) $$B
	$(CREATE_GO_WORK)
	date > $@
whippets.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_WHIPPETS_REPO) $$B
	$(CREATE_GO_WORK)
	date > $@
nekotos.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_NEKOT_REPO) $$B
	$(CREATE_GO_WORK)
	date > $@
copico-bonobo.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_BONOBO_REPO) $$B
	$(CREATE_GO_WORK)
	date > $@
tfr9.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_TFR9_REPO) $$B
	$(CREATE_GO_WORK)
	date > $@
turbos.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_TURBOS_REPO) $$B
	date > $@
godo-client.got:
	B=$(basename $@); set -x; test -d $$B || git clone $(COCO_GODOCLIENT_REPO) $$B
	$(CREATE_GO_WORK)
	date > $@

############################################################################

all-inputs:  \
  inputs/gcc-config-guess \
  inputs/$(COCO_LWTOOLS_TARBALL) \
  inputs/$(COCO_CMOC_TARBALL) \
  inputs/$(COCO_GCCRETRO_TARBALL) \
  inputs/eou-h6309.zip \
  inputs/eou-m6809.zip \
  inputs/eou-101-h6309.zip \
  inputs/eou-101-m6809.zip \
  inputs/$(COCO_PICOSDK_TARBALL) \
  inputs/$(COCO_PICOTOOL_TARBALL) \
  ##

inputs/gcc-config-guess:
	mkdir -p inputs
	# set -x; test -s $@ || curl 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' > $@
	set -x; test -s $@ || curl 'http://pizga.net/inputs/gcc-config-guess' > $@
	expr 33333 '<' $$( wc -c < $@ ) || ( mv $@ $@.BAD ; exit 13 )
inputs/$(COCO_LWTOOLS_TARBALL):
	mkdir -p inputs
	set -x; test -s $@ || curl $(COCO_LWTOOLS_URL) > $@
	expr 33333 '<' $$( wc -c < $@ ) || ( mv $@ $@.BAD ; exit 13 )
inputs/$(COCO_CMOC_TARBALL):
	mkdir -p inputs
	set -x; test -s $@ || curl $(COCO_CMOC_URL) > $@
	expr 33333 '<' $$( wc -c < $@ ) || ( mv $@ $@.BAD ; exit 13 )
inputs/$(COCO_GCCRETRO_TARBALL):
	mkdir -p inputs
	set -x; test -s $@ || curl $(COCO_GCCRETRO_URL) > $@
	expr 33333 '<' $$( wc -c < $@ ) || ( mv $@ $@.BAD ; exit 13 )

inputs/$(COCO_PICOSDK_TARBALL):
	mkdir -p inputs
	set -x; test -s $@ || curl $(COCO_PICOSDK_URL) > $@
	expr 33333 '<' $$( wc -c < $@ ) || ( mv $@ $@.BAD ; exit 13 )
inputs/$(COCO_PICOTOOL_TARBALL):
	mkdir -p inputs
	set -x; test -s $@ || curl $(COCO_PICOTOOL_URL) > $@
	expr 33333 '<' $$( wc -c < $@ ) || ( mv $@ $@.BAD ; exit 13 )

inputs/eou-h6309.zip:
	mkdir -p inputs
	set -x; test -s $@ || curl $(EOU_H6309_URL) > $@
	expr 33333 '<' $$( wc -c < $@ ) || ( mv $@ $@.BAD ; exit 13 )
inputs/eou-m6809.zip:
	mkdir -p inputs
	set -x; test -s $@ || curl $(EOU_M6809_URL) > $@
	expr 33333 '<' $$( wc -c < $@ ) || ( mv $@ $@.BAD ; exit 13 )
inputs/eou-101-h6309.zip:
	mkdir -p inputs
	set -x; test -s $@ || curl $(EOU_101_H6309_URL) > $@
	expr 33333 '<' $$( wc -c < $@ ) || ( mv $@ $@.BAD ; exit 13 )
inputs/eou-101-m6809.zip:
	mkdir -p inputs
	set -x; test -s $@ || curl $(EOU_101_M6809_URL) > $@
	expr 33333 '<' $$( wc -c < $@ ) || ( mv $@ $@.BAD ; exit 13 )

############################################################################

clean-shelf:
	rm -rf build-* done-* *.got *.done go.work
	rm -rf bin share lib libexec usr include .cache
	rm -rf cmoc frobio gccretro lwtools m6809-unknown nitros9 toolshed FoenixMgr
	rm -rf eou-*h6309 eou-*m6809 gomar whippets
	rm -rf nekotos copico-bonobo pico-sdk picotool
	rm -rf tfr9 turbos
	##

_FORCE_:
