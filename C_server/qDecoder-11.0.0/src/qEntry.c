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
 * $Id: qEntry.c 628 2011-01-13 23:41:15Z seungyoung.kim $
 */

/**
 * @file qEntry.c Linked-list Data Structure API
 *
 * @code
 *   [Code sample - String]
 *
 *   // init a linked-list.
 *   Q_ENTRY *entry = qEntry();
 *
 *   // insert a string element
 *   entry->putStr(entry, "str", "hello world", true);
 *
 *   // get the string.
 *   char *str = entry->getStr(entry, "str", false);
 *   if(str != NULL) {
 *     printf("str = %s\n", str);
 *     free(str);
 *   }
 *
 *   // print out all elements in the list.
 *   entry->print(entry, stdout, false);
 *
 *   // free the list.
 *   entry->free(entry);
 *
 *   [Result]
 * @endcode
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdarg.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "internal.h"

/*
 * Member method protos
 */
#ifndef _DOXYGEN_SKIP

#define _VAR		'$'
#define _VAR_OPEN	'{'
#define _VAR_CLOSE	'}'
#define _VAR_CMD	'!'
#define _VAR_ENV	'%'

struct Q_ENTOBJ_T {
        char*           name;           /*!< object name */
        void*           data;           /*!< data object */
        size_t          size;           /*!< object size */
        Q_ENTOBJ_T*     next;           /*!< link pointer */
};
struct Q_ENTRY {
        int             num;            /*!< number of objects */
        size_t          size;           /*!< total size of data objects, does not include name size */
        Q_ENTOBJ_T*     first;          /*!< first object pointer */
        Q_ENTOBJ_T*     last;           /*!< last object pointer */

        /* public member methods */
        void            (*lock)         (Q_ENTRY *entry);
        void            (*unlock)       (Q_ENTRY *entry);

        bool            (*put)          (Q_ENTRY *entry, const char *name, const void *data, size_t size, bool replace);
        bool            (*putStr)       (Q_ENTRY *entry, const char *name, const char *str, bool replace);
        bool            (*putStrf)      (Q_ENTRY *entry, bool replace, const char *name, const char *format, ...);
        bool            (*putInt)       (Q_ENTRY *entry, const char *name, int num, bool replace);

        void*           (*get)          (Q_ENTRY *entry, const char *name, size_t *size, bool newmem);
        void*           (*getCase)      (Q_ENTRY *entry, const char *name, size_t *size, bool newmem);
        void*           (*getLast)      (Q_ENTRY *entry, const char *name, size_t *size, bool newmem);
        char*           (*getStr)       (Q_ENTRY *entry, const char *name, bool newmem);
        char*           (*getStrf)      (Q_ENTRY *entry, bool newmem, const char *namefmt, ...);
        char*           (*getStrCase)   (Q_ENTRY *entry, const char *name, bool newmem);
        char*           (*getStrLast)   (Q_ENTRY *entry, const char *name, bool newmem);
        int             (*getInt)       (Q_ENTRY *entry, const char *name);
        int             (*getIntCase)   (Q_ENTRY *entry, const char *name);
        int             (*getIntLast)   (Q_ENTRY *entry, const char *name);
        bool            (*getNext)      (Q_ENTRY *entry, Q_ENTOBJ_T *obj, const char *name, bool newmem);
        int             (*remove)       (Q_ENTRY *entry, const char *name);

        int             (*getNum)       (Q_ENTRY *entry);

        bool            (*truncate)     (Q_ENTRY *entry);
        bool            (*save)         (Q_ENTRY *entry, const char *filepath);
        int             (*load)         (Q_ENTRY *entry, const char *filepath);
        bool            (*reverse)      (Q_ENTRY *entry);
        bool            (*print)        (Q_ENTRY *entry, FILE *out, bool print_data);
        bool            (*free)         (Q_ENTRY *entry);
};



static bool		_put(Q_ENTRY *entry, const char *name, const void *data, size_t size, bool replace);
static bool		_putStr(Q_ENTRY *entry, const char *name, const char *str, bool replace);
static bool		_putStrf(Q_ENTRY *entry, bool replace, const char *name, const char *format, ...);
static bool		_putInt(Q_ENTRY *entry, const char *name, int num, bool replace);

static void*		_get(Q_ENTRY *entry, const char *name, size_t *size, bool newmem);
static void*		_getCase(Q_ENTRY *entry, const char *name, size_t *size, bool newmem);
static void*		_getLast(Q_ENTRY *entry, const char *name, size_t *size, bool newmem);
static char*		_getStr(Q_ENTRY *entry, const char *name, bool newmem);
static char*		_getStrf(Q_ENTRY *entry, bool newmem, const char *namefmt, ...);
static char*		_getStrCase(Q_ENTRY *entry, const char *name, bool newmem);
static char*		_getStrLast(Q_ENTRY *entry, const char *name, bool newmem);
static int		_getInt(Q_ENTRY *entry, const char *name);
static int		_getIntCase(Q_ENTRY *entry, const char *name);
static int 		_getIntLast(Q_ENTRY *entry, const char *name);
static bool		_getNext(Q_ENTRY *entry, Q_ENTOBJ_T *obj, const char *name, bool newmem);

static int		_remove(Q_ENTRY *entry, const char *name);

static int 		_getNum(Q_ENTRY *entry);

static bool		_truncate(Q_ENTRY *entry);
static bool		_reverse(Q_ENTRY *entry);
static bool		_print(Q_ENTRY *entry, FILE *out, bool print_data);
static bool		_free(Q_ENTRY *entry);

#endif

/**
 * Create new Q_ENTRY linked-list object
 *
 * @return	a pointer of malloced Q_ENTRY structure in case of successful, otherwise returns NULL.
 *
 * @code
 *   Q_ENTRY *entry = qEntry();
 * @endcode
 */
Q_ENTRY *qEntry(void) {
	Q_ENTRY *entry = (Q_ENTRY *)malloc(sizeof(Q_ENTRY));
	if(entry == NULL) return NULL;

	memset((void *)entry, 0, sizeof(Q_ENTRY));

	// member methods
	entry->put		= _put;
	entry->putStr		= _putStr;
	entry->putStrf		= _putStrf;
	entry->putInt		= _putInt;

	entry->get		= _get;
	entry->getCase		= _getCase;
	entry->getLast		= _getLast;

	entry->getStr		= _getStr;
	entry->getStrf		= _getStrf;
	entry->getStrCase	= _getStrCase;
	entry->getStrLast	= _getStrLast;
	entry->getInt		= _getInt;
	entry->getIntCase	= _getIntCase;
	entry->getIntLast	= _getIntLast;

	entry->getNext		= _getNext;

	entry->remove		= _remove;

	entry->getNum		= _getNum;

	entry->truncate		= _truncate;
	entry->save		= _save;
	entry->load		= _load;
	entry->reverse		= _reverse;
	entry->print		= _print;
	entry->free		= _free;

	return entry;
}

/**
 * Q_ENTRY->put(): Store object into linked-list structure.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name.
 * @param	object	object pointer
 * @param	size	size of the object
 * @param	replace	in case of false, just insert. in case of true, remove all same key then insert object if found.
 *
 * @return	true if successful, otherwise returns false.
 */
static bool _put(Q_ENTRY *entry, const char *name, const void *data, size_t size, bool replace) {
	// check arguments
	if(entry == NULL || name == NULL || data == NULL || size <= 0) return false;

	// duplicate name
	char *dup_name = strdup(name);
	if(dup_name == NULL) return false;

	// duplicate object
	void *dup_data = malloc(size);
	if(dup_data == NULL) {
		free(dup_name);
		return false;
	}
	memcpy(dup_data, data, size);

	// make new object entry
	Q_ENTOBJ_T *obj = (Q_ENTOBJ_T*)malloc(sizeof(Q_ENTOBJ_T));
	if(obj == NULL) {
		free(dup_name);
		free(dup_data);
		return false;
	}
	obj->name = dup_name;
	obj->data = dup_data;
	obj->size = size;
	obj->next = NULL;

	// if replace flag is set, remove same key
	if (replace == true) _remove(entry, dup_name);

	// make chain link
	if(entry->first == NULL) entry->first = entry->last = obj;
	else {
		entry->last->next = obj;
		entry->last = obj;
	}

	entry->size += size;
	entry->num++;

	return true;
}

/**
 * Q_ENTRY->putStr(): Add string object into linked-list structure.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name.
 * @param	str	string value
 * @param	replace	in case of false, just insert. in case of true, remove all same key then insert object if found.
 *
 * @return	true if successful, otherwise returns false.
 */
static bool _putStr(Q_ENTRY *entry, const char *name, const char *str, bool replace) {
	size_t size = (str!=NULL) ? (strlen(str) + 1) : 0;
	return _put(entry, name, (const void *)str, size, replace);
}

/**
 * Q_ENTRY->putStrf(): Add formatted string object into linked-list structure.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	replace	in case of false, just insert. in case of true, remove all same key then insert object if found.
 * @param	name	key name.
 * @param	format	formatted value string
 *
 * @return	true if successful, otherwise returns false.
 */
static bool _putStrf(Q_ENTRY *entry, bool replace, const char *name, const char *format, ...) {
	char *str;
	DYNAMIC_VSPRINTF(str, format);
	if(str == NULL) return false;

	bool ret = _putStr(entry, name, str, replace);
	free(str);

	return ret;
}

/**
 * Q_ENTRY->putInt(): Add integer object into linked-list structure.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name.
 * @param	num	number value
 * @param	replace	in case of false, just insert. in case of true, remove all same key then insert object if found.
 *
 * @return	true if successful, otherwise returns false.
 */
static bool _putInt(Q_ENTRY *entry, const char *name, int num, bool replace) {
	char str[10+1];
	sprintf(str, "%d", num);
	return _put(entry, name, (void *)str, strlen(str) + 1, replace);
}

/**
 * Q_ENTRY->get(): Find object with given name
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name
 * @param	size	if size is not NULL, object size will be stored.
 * @param	newmem	whether or not to allocate memory for the data.
 *
 * @return	a pointer of data if key is found, otherwise returns NULL.
 *
 * @code
 *   Q_ENTRY *entry = qEntry();
 *   (...codes...)
 *
 *   // with newmem flag unset
 *   size_t size;
 *   const char *data = entry->get(entry, "key_name", &size, false);
 *
 *   // with newmem flag set
 *   size_t size;
 *   char *data = entry->get(entry, "key_name", &size, true);
 *   if(data != NULL) free(data);
 * @endcode
 *
 * @note
 * If newmem flag is set, returned data will be malloced and should be deallocated by user.
 * Otherwise returned pointer will point internal buffer directly and should not be de-allocated by user.
 * In thread-safe mode, newmem flag always should be true.
 */
static void *_get(Q_ENTRY *entry, const char *name, size_t *size, bool newmem) {
	if(entry == NULL || name == NULL) return NULL;

	void *data = NULL;
	Q_ENTOBJ_T *obj;
	for(obj = entry->first; obj; obj = obj->next) {
		if(!strcmp(obj->name, name)) {
			if(size != NULL) *size = obj->size;

			if(newmem == true) {
				data = malloc(obj->size);
				memcpy(data, obj->data, obj->size);
			} else {
				data = obj->data;
			}

			break;
		}
	}

	return data;
}

/**
 * Q_ENTRY->getCase(): Find object with given name. (case-insensitive)
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name
 * @param	size	if size is not NULL, object size will be stored.
 * @param	newmem	whether or not to allocate memory for the data.
 *
 * @return	a pointer of malloced data if key is found, otherwise returns NULL.
 */
static void *_getCase(Q_ENTRY *entry, const char *name, size_t *size, bool newmem) {
	if(entry == NULL || name == NULL) return NULL;

	void *data = NULL;
	Q_ENTOBJ_T *obj;
	for(obj = entry->first; obj; obj = obj->next) {
		if(!strcasecmp(name, obj->name)) {
			if(size != NULL) *size = obj->size;
			if(newmem == true) {
				data = malloc(obj->size);
				memcpy(data, obj->data, obj->size);
			} else {
				data = obj->data;
			}

			break;
		}
	}

	return data;
}

/**
 * Q_ENTRY->getLast(): Find lastest matched object with given name.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name
 * @param	size	if size is not NULL, object size will be stored.
 * @param	newmem	whether or not to allocate memory for the data.
 *
 * @return	a pointer of malloced data if key is found, otherwise returns NULL.
 *
 * @note
 * If you have multiple objects with same name. this method can be used to
 * find out lastest matched object.
 */
static void *_getLast(Q_ENTRY *entry, const char *name, size_t *size, bool newmem) {
	if(entry == NULL || name == NULL) return NULL;

	Q_ENTOBJ_T *lastobj = NULL;
	Q_ENTOBJ_T *obj;
	for(obj = entry->first; obj; obj = obj->next) {
		if (!strcmp(name, obj->name)) lastobj = obj;
	}

	void *data = NULL;
	if(lastobj != NULL) {
		if(size != NULL) *size = lastobj->size;
		if(newmem == true) {
			data = malloc(lastobj->size);
			memcpy(data, lastobj->data, lastobj->size);
		} else {
			data = lastobj->data;
		}
	}

	return data;
}

/**
 * Q_ENTRY->getStr():  Find string object with given name.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name
 * @param	newmem	whether or not to allocate memory for the data.
 *
 * @return	a pointer of malloced data if key is found, otherwise returns NULL.
 */
static char *_getStr(Q_ENTRY *entry, const char *name, bool newmem) {
	return (char *)_get(entry, name, NULL, newmem);
}

/**
 * Q_ENTRY->_getStrf():  Find string object with given formatted name.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	newmem	whether or not to allocate memory for the data.
 * @param	namefmt	formatted name string
 *
 * @return	a pointer of malloced data if key is found, otherwise returns NULL.
 */
static char *_getStrf(Q_ENTRY *entry, bool newmem, const char *namefmt, ...) {
	char *name;
	DYNAMIC_VSPRINTF(name, namefmt);
	if(name == NULL) return NULL;

	char *data = (char*)_get(entry, name, NULL, newmem);
	free(name);

	return data;
}

/**
 * Q_ENTRY->getStrCase(): Find string object with given name. (case-insensitive)
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name
 * @param	newmem	whether or not to allocate memory for the data.
 *
 * @return	a pointer of malloced data if key is found, otherwise returns NULL.
 */
static char *_getStrCase(Q_ENTRY *entry, const char *name, bool newmem) {
	return (char *)_getCase(entry, name, NULL, newmem);
}

/**
 * Q_ENTRY->getStrLast(): Find lastest matched string object with given name.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name
 * @param	newmem	whether or not to allocate memory for the data.
 *
 * @return	a pointer of malloced data if key is found, otherwise returns NULL.
 */
static char *_getStrLast(Q_ENTRY *entry, const char *name, bool newmem) {
	return (char *)_getLast(entry, name, NULL, newmem);
}

/**
 * Q_ENTRY->getInt(): Find integer object with given name.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name
 *
 * @return	a integer value of the integer object, otherwise returns 0.
 */
static int _getInt(Q_ENTRY *entry, const char *name) {
	char *str = _get(entry, name, NULL, true);
	int n = 0;
	if(str != NULL) {
		n = atoi(str);
		free(str);
	}
	return n;
}

/**
 * Q_ENTRY->getIntCase(): Find integer object with given name. (case-insensitive)
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name
 *
 * @return	a integer value of the object.
 */
static int _getIntCase(Q_ENTRY *entry, const char *name) {
	char *str =_getCase(entry, name, NULL, true);
	int n = 0;
	if(str != NULL) {
		n = atoi(str);
		free(str);
	}
	return n;
}

/**
 * Q_ENTRY->getIntLast(): Find lastest matched integer object with given name.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name
 *
 * @return	a integer value of the object.
 */
static int _getIntLast(Q_ENTRY *entry, const char *name) {
	char *str =_getLast(entry, name, NULL, true);
	int n = 0;
	if(str != NULL) {
		n = atoi(str);
		free(str);
	}
	return n;

}

/**
 * Q_ENTRY->getNext(): Get next object structure.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	obj	found data will be stored in this object
 * @param	name	key name, if key name is NULL search every key in the list.
 * @param	newmem	whether or not to allocate memory for the data.
 *
 * @return	true if found otherwise returns false
 *
 * @note
 * obj should be filled with 0 by using memset() before first call.
 * If newmem flag is true, user should de-allocate obj.name and obj.data resources.
 *
 * @code
 *   Q_ENTRY *entry = qEntry();
 *   entry->putStr(entry, "key1", "hello world 1", false);
 *   entry->putStr(entry, "key2", "hello world 2", false);
 *   entry->putStr(entry, "key3", "hello world 3", false);
 *
 *   Q_ENTOBJ_T obj;
 *   memset((void*)&obj, 0, sizeof(obj)); // must be cleared before call
 *   while(entry->getNext(entry, &obj, NULL, false) == true) {
 *     printf("NAME=%s, DATA=%s", SIZE=%zu", obj.name, obj.data, obj.size);
 *   }
 *
 *   // with newmem flag
 *   Q_ENTOBJ_T obj;
 *   memset((void*)&obj, 0, sizeof(obj)); // must be cleared before call
 *   while(entry->getNext(entry, &obj, NULL, true) == true) {
 *     printf("NAME=%s, DATA=%s", SIZE=%zu", obj.name, obj.data, obj.size);
 *     free(obj.name);
 *     free(obj.data);
 *   }
 * @endcode
 */
static bool _getNext(Q_ENTRY *entry, Q_ENTOBJ_T *obj, const char *name, bool newmem) {
	if(entry == NULL || obj == NULL) return NULL;

	// if obj->name is NULL, it means this is first call.
	if(obj->name == NULL) obj->next = entry->first;

	Q_ENTOBJ_T *cont;
	bool ret = false;
	for(cont = obj->next; cont; cont = cont->next) {
		if(name != NULL && strcmp(cont->name, name)) continue;

		if(newmem == true) {
			obj->name = strdup(cont->name);
			obj->data = malloc(cont->size);
			memcpy(obj->data, cont->data, cont->size);
		} else {
			obj->name = cont->name;
			obj->data = cont->data;
		}
		obj->size = cont->size;
		obj->next = cont->next;

		ret = true;
		break;
	}

	return ret;
}

/**
 * Q_ENTRY->remove(): Remove matched objects as given name.
 *
 * @param	entry	Q_ENTRY pointer
 * @param	name	key name
 *
 * @return	a number of removed objects.
 */
static int _remove(Q_ENTRY *entry, const char *name) {
	if(entry == NULL || name == NULL) return 0;

	int removed = 0;
	Q_ENTOBJ_T *prev, *obj;
	for (prev = NULL, obj = entry->first; obj;) {
		if (!strcmp(obj->name, name)) { // found
			// copy next chain
			Q_ENTOBJ_T *next = obj->next;

			// adjust counter
			entry->size -= obj->size;
			entry->num--;
			removed++;

			// remove entry itself
			free(obj->name);
			free(obj->data);
			free(obj);

			// adjust chain links
			if(next == NULL) entry->last = prev;	// if the object is last one
			if(prev == NULL) entry->first = next;	// if the object is first one
			else prev->next = next;			// if the object is middle or last one

			// set next entry
			obj = next;
		} else {
			// remember prev object
			prev = obj;

			// set next entry
			obj = obj->next;
		}
	}

	return removed;
}

/**
 * Q_ENTRY->getNum(): Get total number of stored objects
 *
 * @param	entry	Q_ENTRY pointer
 *
 * @return	total number of stored objects.
 */
static int _getNum(Q_ENTRY *entry) {
	if(entry == NULL) return 0;

	return entry->num;
}

/**
 * Q_ENTRY->truncate(): Truncate Q_ENTRY
 *
 * @param	entry	Q_ENTRY pointer
 *
 * @return	always returns true.
 */
static bool _truncate(Q_ENTRY *entry) {
	if(entry == NULL) return false;

	Q_ENTOBJ_T *obj;
	for(obj = entry->first; obj;) {
		Q_ENTOBJ_T *next = obj->next;
		free(obj->name);
		free(obj->data);
		free(obj);
		obj = next;
	}

	entry->num = 0;
	entry->size = 0;
	entry->first = NULL;
	entry->last = NULL;

	return true;
}

/**
 * Q_ENTRY->save(): Save Q_ENTRY as plain text format
 *
 * @param	entry	Q_ENTRY pointer
 * @param	filepath save file path
 *
 * @return	true if successful, otherwise returns false.
 */

/**
 * Q_ENTRY->load(): Load and append entries from given filepath
 *
 * @param	entry	Q_ENTRY pointer
 * @param	filepath save file path
 *
 * @return	a number of loaded entries.
 */

/**
 * Q_ENTRY->reverse(): Reverse-sort internal stored object.
 *
 * @param	entry	Q_ENTRY pointer
 *
 * @return	true if successful otherwise returns false.
 *
 * @note
 * This method can be used to improve look up performance.
 * if your application offen looking for last stored object.
 */
static bool _reverse(Q_ENTRY *entry) {
	if(entry == NULL) return false;

	Q_ENTOBJ_T *prev, *obj;
	for (prev = NULL, obj = entry->first; obj;) {
		Q_ENTOBJ_T *next = obj->next;
		obj->next = prev;
		prev = obj;
		obj = next;
	}

	entry->last = entry->first;
	entry->first = prev;

	return true;
}

/**
 * Q_ENTRY->print(): Print out stored objects for debugging purpose.
 *
 * @param	entry		Q_ENTRY pointer
 * @param	out		output stream FILE descriptor such like stdout, stderr.
 * @param	print_data	true for printing out object value, false for disable printing out object value.
 */
static bool _print(Q_ENTRY *entry, FILE *out, bool print_data) {
	if(entry == NULL || out == NULL) return false;

	Q_ENTOBJ_T *obj;
	for(obj = entry->first; obj; obj = obj->next) {
		fprintf(out, "%s=%s (%zu)\n" , obj->name, (print_data?(char*)obj->data:"(data)"), obj->size);
	}

	return true;
}

/**
 * Q_ENTRY->free(): Free Q_ENTRY
 *
 * @param	entry	Q_ENTRY pointer
 *
 * @return	always returns true.
 */
static bool _free(Q_ENTRY *entry) {
	if(entry == NULL) return false;

	_truncate(entry);

	free(entry);
	return true;
}
