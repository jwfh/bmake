#	$Id: Makefile,v 1.20 2013/09/04 15:42:03 sjg Exp $

# Base version on src date
MAKE_VERSION= 20130904

PROG=	bmake

SRCS= \
	arch.c \
	buf.c \
	compat.c \
	cond.c \
	dir.c \
	for.c \
	hash.c \
	job.c \
	main.c \
	make.c \
	make_malloc.c \
	meta.c \
	parse.c \
	str.c \
	strlist.c \
	suff.c \
	targ.c \
	trace.c \
	util.c \
	var.c

# from lst.lib/
SRCS+= \
	lstAppend.c \
	lstAtEnd.c \
	lstAtFront.c \
	lstClose.c \
	lstConcat.c \
	lstDatum.c \
	lstDeQueue.c \
	lstDestroy.c \
	lstDupl.c \
	lstEnQueue.c \
	lstFind.c \
	lstFindFrom.c \
	lstFirst.c \
	lstForEach.c \
	lstForEachFrom.c \
	lstInit.c \
	lstInsert.c \
	lstIsAtEnd.c \
	lstIsEmpty.c \
	lstLast.c \
	lstMember.c \
	lstNext.c \
	lstOpen.c \
	lstPrev.c \
	lstRemove.c \
	lstReplace.c \
	lstSucc.c

# this file gets generated by configure
.-include "Makefile.config"

.if !empty(LIBOBJS)
SRCS+= ${LIBOBJS:T:.o=.c}
.endif

# just in case
prefix?= /usr
srcdir?= ${.CURDIR}

DEFAULT_SYS_PATH?= .../share/mk:${prefix}/share/mk

CPPFLAGS+= -DUSE_META
CFLAGS+= ${CPPFLAGS}
CFLAGS+= -D_PATH_DEFSYSPATH=\"${DEFAULT_SYS_PATH}\"
CFLAGS+= -I. -I${srcdir} ${XDEFS} -DMAKE_NATIVE
CFLAGS+= ${COPTS.${.ALLSRC:M*.c:T:u}}
COPTS.main.c+= "-DMAKE_VERSION=\"${MAKE_VERSION}\""

# meta mode can be useful even without filemon 
FILEMON_H ?= /usr/include/dev/filemon/filemon.h
.if exists(${FILEMON_H}) && ${FILEMON_H:T} == "filemon.h"
COPTS.meta.c += -DHAVE_FILEMON_H -I${FILEMON_H:H}
.endif

.PATH:	${srcdir}
.PATH:	${srcdir}/lst.lib

.if make(obj) || make(clean)
SUBDIR+= unit-tests
.endif

# start-delete1 for bsd.after-import.mk
# we skip a lot of this when building as part of FreeBSD etc.

# list of OS's which are derrived from BSD4.4
BSD44_LIST= NetBSD FreeBSD OpenBSD DragonFly
# we are...
OS!= uname -s
# are we 4.4BSD ?
isBSD44:=${BSD44_LIST:M${OS}}

.if ${isBSD44} == ""
MANTARGET= cat
INSTALL?=${srcdir}/install-sh
.if (${MACHINE} == "sun386")
# even I don't have one of these anymore :-)
CFLAGS+= -DPORTAR
.elif (${MACHINE} != "sunos")
SRCS+= sigcompat.c
CFLAGS+= -DSIGNAL_FLAGS=SA_RESTART
.endif
.else
MANTARGET?= man
.endif

# turn this on by default - ignored if we are root
WITH_INSTALL_AS_USER=

# supress with -DWITHOUT_*
OPTIONS_DEFAULT_YES+= \
	AUTOCONF_MK \
	INSTALL_MK \
	PROG_LINK

OPTIONS_DEFAULT_NO+= \
	PROG_VERSION

# process options now
.include <own.mk>

.if ${MK_PROG_VERSION} == "yes"
PROG_NAME= ${PROG}-${MAKE_VERSION}
.if ${MK_PROG_LINK} == "yes"
SYMLINKS+= ${PROG}-${MAKE_VERSION} ${BINDIR}/${PROG}
.endif
.endif

EXTRACT_MAN=no
# end-delete1

MAN= ${PROG}.1
MAN1= ${MAN}

.if (${PROG} != "make")
CLEANFILES+= my.history
.if make(${MAN}) || !exists(${srcdir}/${MAN})
my.history: ${MAKEFILE}
	@(echo ".Nm"; \
	echo "is derived from NetBSD"; \
	echo ".Xr make 1 ."; \
	echo "It uses autoconf to facilitate portability to other platforms."; \
	echo ".Pp") > $@

.NOPATH: ${MAN}
${MAN}:	make.1 my.history
	@echo making $@
	@sed -e 's/^.Nx/NetBSD/' -e '/^.Nm/s/make/${PROG}/' \
	-e '/^.Sh HISTORY/rmy.history' \
	-e '/^.Sh HISTORY/,$$s,^.Nm,make,' ${srcdir}/make.1 > $@

all beforeinstall: ${MAN}
_mfromdir=.
.endif
.endif

MANTARGET?= cat
MANDEST?= ${MANDIR}/${MANTARGET}1

.if ${MANTARGET} == "cat"
_mfromdir=${srcdir}
.endif

.include <prog.mk>

CPPFLAGS+= -DMAKE_NATIVE -DHAVE_CONFIG_H
COPTS.var.c += -Wno-cast-qual
COPTS.job.c += -Wno-format-nonliteral
COPTS.parse.c += -Wno-format-nonliteral
COPTS.var.c += -Wno-format-nonliteral

# Force these
SHAREDIR= ${prefix}/share
BINDIR= ${prefix}/bin
MANDIR= ${SHAREDIR}/man

.if !exists(.depend)
${OBJS}: config.h
.endif

# make sure that MAKE_VERSION gets updated.
main.o: ${SRCS} ${MAKEFILE}

# start-delete2 for bsd.after-import.mk
.if ${MK_AUTOCONF_MK} == "yes"
.include <autoconf.mk>
.endif
SHARE_MK?=${SHAREDIR}/mk
MKSRC=${srcdir}/mk
INSTALL?=${srcdir}/install-sh

.if ${MK_INSTALL_MK} == "yes"
install: install-mk
.endif

beforeinstall:
	test -d ${DESTDIR}${BINDIR} || ${INSTALL} -m 775 -d ${DESTDIR}${BINDIR}
	test -d ${DESTDIR}${MANDEST} || ${INSTALL} -m 775 -d ${DESTDIR}${MANDEST}

install-mk:
.if exists(${MKSRC}/install-mk)
	test -d ${DESTDIR}${SHARE_MK} || ${INSTALL} -m 775 -d ${DESTDIR}${SHARE_MK}
	sh ${MKSRC}/install-mk -v -m 644 ${DESTDIR}${SHARE_MK}
.else
	@echo need to unpack mk.tar.gz under ${srcdir} or set MKSRC; false
.endif
# end-delete2

# A simple unit-test driver to help catch regressions
accept test:
	cd ${.CURDIR}/unit-tests && MAKEFLAGS= ${.MAKE} -r -m / TEST_MAKE=${TEST_MAKE:U${.OBJDIR}/${PROG:T}} ${.TARGET}