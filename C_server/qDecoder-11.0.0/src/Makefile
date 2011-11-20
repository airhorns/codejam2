## Copyright 2000-2010 The qDecoder Project. All rights reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
##
## 1. Redistributions of source code must retain the above copyright
##    notice, this list of conditions and the following disclaimer.
## 2. Redistributions in binary form must reproduce the above copyright
##    notice, this list of conditions and the following disclaimer in the
##    documentation and/or other materials provided with the distribution.
##
## THIS SOFTWARE IS PROVIDED BY THE QDECODER PROJECT ``AS IS'' AND ANY
## EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
## DISCLAIMED. IN NO EVENT SHALL THE QDECODER PROJECT BE LIABLE FOR ANY
## DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
## (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
## LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
## ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
## (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
## THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
## $Id: Makefile.in 626 2011-01-13 23:16:55Z seungyoung.kim $

prefix		= /usr/local
exec_prefix	= ${prefix}

## Name
PRGNAME		= qdecoder

## Static Library Name
LIBNAME		= lib${PRGNAME}.a

## Shared Library Name
SLIBVERSION	= 11
SLIBNAME	= lib${PRGNAME}.so
SLIBREALNAME	= ${SLIBNAME}.${SLIBVERSION}

## System library directory
LIBDIR		= ${exec_prefix}/lib
HEADERDIR	= ${prefix}/include

## Which compiler & options for release
CC		= gcc
CFLAGS		= -Wall -fPIC -g -O2
CPPFLAGS	=  -I/usr/include -I/usr/local/include -I./ -D_GNU_SOURCE

## Utilities
AR		= /usr/bin/ar
ARFLAGS		= -rc
CHMOD		= /bin/chmod
INSTALL		= /usr/bin/install -c
INSTALL_DATA	= ${INSTALL} -m 644
LN_S		= ln -s
RANLIB		= ranlib
RM		= /bin/rm

## Objects List
OBJ		= qCgiRequest.o		\
		  qCgiResponse.o	\
		  qSession.o		\
		  qEntry.o		\
		  internal.o

## Make Library
all: qdecoder

qdecoder: ${OBJ}
	${AR} ${ARFLAGS} ${LIBNAME} ${OBJ}
	${RANLIB} ${LIBNAME}
	${CC} -shared -Wl,-soname,${SLIBREALNAME} -o ${SLIBREALNAME} ${OBJ}
	${LN_S} -f ${SLIBREALNAME} ${SLIBNAME}

install: all
	${INSTALL_DATA} qdecoder.h ${HEADERDIR}/qdecoder.h
	${INSTALL_DATA} ${LIBNAME} ${LIBDIR}/${LIBNAME}
	${INSTALL_DATA} ${SLIBREALNAME} ${LIBDIR}/${SLIBREALNAME}
	${LN_S} -f ${LIBDIR}/${SLIBREALNAME} ${LIBDIR}/${SLIBNAME}

deinstall: uninstall
uninstall:
	${RM} -f ${HEADERDIR}/qdecoder.h
	${RM} -f ${LIBDIR}/${LIBNAME}
	${RM} -f ${LIBDIR}/${SLIBREALNAME}
	${RM} -f ${LIBDIR}/${SLIBNAME}

doc:
	doxygen doxygen.conf

cleandoc:
	${RM} -rf ../doc/html

clean:
	${RM} -f ${OBJ} ${LIBNAME} ${SLIBREALNAME} ${SLIBNAME}

## Compile
.c.o:
	${CC} ${CFLAGS} ${CPPFLAGS} -c -o $@ $<
