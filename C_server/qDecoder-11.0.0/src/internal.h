/*
 * Copyright 2000-2010 The qDecoder Project. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE QDECODER PROJECT ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE QDECODER PROJECT BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: internal.h 621 2011-01-13 22:44:42Z seungyoung.kim $
 */

#ifndef _QINTERNAL_H
#define _QINTERNAL_H

#include <fcntl.h>

/*
 * Internal Macros
 */
#ifdef BUILD_DEBUG
#define DEBUG(fmt, args...)	fprintf(stderr, "[DEBUG] " fmt " (%s:%d)\n", ##args, __FILE__, __LINE__);
#else
#define DEBUG(fms, args...)
#endif	/* BUILD_DEBUG */

/*
 * Macro Functions
 */
#define	CONST_STRLEN(x)		(sizeof(x) - 1)

#define	DYNAMIC_VSPRINTF(s, f)							\
do {										\
	size_t _strsize;							\
	for(_strsize = 1024; ; _strsize *= 2) {					\
		s = (char*)malloc(_strsize);					\
		if(s == NULL) {							\
			DEBUG("DYNAMIC_VSPRINTF(): can't allocate memory.");	\
			break;							\
		}								\
		va_list _arglist;						\
		va_start(_arglist, f);						\
		int _n = vsnprintf(s, _strsize, f, _arglist);			\
		va_end(_arglist);						\
		if(_n >= 0 && _n < _strsize) break;				\
		free(s);							\
	}									\
} while(0)

/*
 * Internal Definitions
 */
#define	MAX_LINEBUF		(1023+1)
#define	DEF_DIR_MODE		(S_IRUSR|S_IWUSR|S_IXUSR|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH)
#define	DEF_FILE_MODE		(S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH)

/*
 * qInternalCommon.c
 */
extern	char	_qdecoder_x2c(char hex_up, char hex_low);
extern	char*	_qdecoder_makeword(char *str, char stop);
extern	char*	_qdecoder_urlencode(const void *bin, size_t size);
extern	size_t	_qdecoder_urldecode(char *str);
extern	char*	_qdecoder_fgets(char *str, size_t size, FILE *fp);
extern	char*	_qdecoder_fgetline(FILE *fp, size_t initsize);
extern	int	_qdecoder_unlink(const char *pathname);
extern	char*	_qdecoder_strcpy(char *dst, size_t size, const char *src);
extern	char*	_qdecoder_strtrim(char *str);
extern	char*	_qdecoder_strunchar(char *str, char head, char tail);
extern	char*	_qdecoder_filename(const char *filepath);
extern	off_t	_qdecoder_filesize(const char *filepath);
extern	off_t	_qdecoder_iosend(int outfd, int infd, off_t nbytes);
extern	int	_qdecoder_countread(const char *filepath);
extern	bool	_qdecoder_countsave(const char *filepath, int number);

/*
 * To prevent compiler warning
 */
extern	char*	strptime(const char *, const char *, struct tm *);

#endif	/* _QINTERNAL_H */
