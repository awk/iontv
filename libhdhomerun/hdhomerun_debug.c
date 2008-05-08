/*
 * hdhomerun_debug.c
 *
 * Copyright © 2006 Silicondust Engineering Ltd. <www.silicondust.com>.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/*
 * The debug logging includes optional support for connecting to the
 * Silicondust support server. This option should not be used without
 * being explicitly enabled by the user. Debug information should be
 * limited to information useful to diagnosing a problem.
 *  - Silicondust.
 */

#include "hdhomerun_os.h"
#include "hdhomerun_debug.h"

struct hdhomerun_debug_message_t
{
	struct hdhomerun_debug_message_t *next;
	struct hdhomerun_debug_message_t *prev;
	char buffer[2048];
};

struct hdhomerun_debug_t
{
	pthread_t thread;
	volatile bool_t terminate;

	pthread_mutex_t queue_lock;
	struct hdhomerun_debug_message_t *queue_head;
	struct hdhomerun_debug_message_t *queue_tail;

	pthread_mutex_t file_lock;
	FILE *log_file;

	pthread_mutex_t server_lock;
	bool_t server_enabled;
	int server_sock;
	uint64_t server_delay;
};

static THREAD_FUNC_PREFIX hdhomerun_debug_thread_execute(void *arg);

struct hdhomerun_debug_t *hdhomerun_debug_create(void)
{
	struct hdhomerun_debug_t *dbg = (struct hdhomerun_debug_t *)calloc(1, sizeof(struct hdhomerun_debug_t));
	if (!dbg) {
		return NULL;
	}

	dbg->log_file = NULL;
	dbg->server_sock = -1;
	dbg->terminate = FALSE;

	pthread_mutex_init(&dbg->queue_lock, NULL);
	pthread_mutex_init(&dbg->file_lock, NULL);
	pthread_mutex_init(&dbg->server_lock, NULL);

	if (pthread_create(&dbg->thread, NULL, &hdhomerun_debug_thread_execute, dbg) != 0) {
		free(dbg);
		return NULL;
	}

	return dbg;
}

void hdhomerun_debug_destroy(struct hdhomerun_debug_t *dbg)
{
	dbg->terminate = TRUE;
	pthread_join(dbg->thread, NULL);

	if (dbg->server_sock != -1) {
		close(dbg->server_sock);
	}
	if (dbg->log_file) {
		fclose(dbg->log_file);
	}

	free(dbg);
}

void hdhomerun_debug_enable_log_file(struct hdhomerun_debug_t *dbg, char *filename)
{
	pthread_mutex_lock(&dbg->file_lock);

	if (!dbg->log_file) {
		dbg->log_file = fopen(filename, "a");
	}

	pthread_mutex_unlock(&dbg->file_lock);
}

void hdhomerun_debug_disable_log_file(struct hdhomerun_debug_t *dbg)
{
	pthread_mutex_lock(&dbg->file_lock);

	if (dbg->log_file) {
		fclose(dbg->log_file);
		dbg->log_file = NULL;
	}

	pthread_mutex_unlock(&dbg->file_lock);
}

void hdhomerun_debug_enable_support_server(struct hdhomerun_debug_t *dbg)
{
	pthread_mutex_lock(&dbg->server_lock);

	dbg->server_enabled = TRUE;

	pthread_mutex_unlock(&dbg->server_lock);
}

void hdhomerun_debug_disable_support_server(struct hdhomerun_debug_t *dbg)
{
	pthread_mutex_lock(&dbg->server_lock);

	dbg->server_enabled = FALSE;
	if (dbg->server_sock != -1) {
		close(dbg->server_sock);
		dbg->server_sock = -1;
	}

	pthread_mutex_unlock(&dbg->server_lock);
}

bool_t hdhomerun_debug_enabled(struct hdhomerun_debug_t *dbg)
{
	if (!dbg) {
		return FALSE;
	}

	if (dbg->log_file) {
		return TRUE;
	}
	if (dbg->server_enabled) {
		return TRUE;
	}

	return FALSE;
}

void hdhomerun_debug_printf(struct hdhomerun_debug_t *dbg, const char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	hdhomerun_debug_vprintf(dbg, fmt, args);
	va_end(args);
}

void hdhomerun_debug_vprintf(struct hdhomerun_debug_t *dbg, const char *fmt, va_list args)
{
	if (!dbg) {
		return;
	}

	struct hdhomerun_debug_message_t *message = (struct hdhomerun_debug_message_t *)malloc(sizeof(struct hdhomerun_debug_message_t));
	if (!message) {
		return;
	}

	char *ptr = message->buffer;
	char *end = message->buffer + sizeof(message->buffer) - 2;
	*end = 0;

	time_t t = time(NULL);
	strftime(ptr, end - ptr, "%Y%m%d-%H:%M:%S ", localtime(&t));

	ptr = strchr(ptr, '\0');
	vsnprintf(ptr, end - ptr, fmt, args);

	ptr = strchr(ptr, '\0') - 1;
	if (*ptr++ != '\n') {
		*ptr++ = '\n';
		*ptr++ = 0;
	}

	pthread_mutex_lock(&dbg->queue_lock);

	message->prev = NULL;
	message->next = dbg->queue_head;
	dbg->queue_head = message;
	if (message->next) {
		message->next->prev = message;
	} else {
		dbg->queue_tail = message;
	}

	pthread_mutex_unlock(&dbg->queue_lock);
}

static void hdhomerun_debug_output_message_log_file(struct hdhomerun_debug_t *dbg, struct hdhomerun_debug_message_t *message)
{
	if (!dbg->log_file) {
		return;
	}

	fwrite(message->buffer, 1, strlen(message->buffer), dbg->log_file);
}

#if defined(__CYGWIN__)
static void hdhomerun_debug_output_message_support_server(struct hdhomerun_debug_t *dbg, struct hdhomerun_debug_message_t *message)
{
}
#else
static void hdhomerun_debug_output_message_support_server(struct hdhomerun_debug_t *dbg, struct hdhomerun_debug_message_t *message)
{
	if (!dbg->server_enabled) {
		return;
	}

	if (dbg->server_sock == -1) {
		uint64_t current_time = getcurrenttime();
		if (current_time < dbg->server_delay) {
			return;
		}
		dbg->server_delay = current_time + 60*1000;

		dbg->server_sock = (int)socket(AF_INET, SOCK_STREAM, 0);
		if (dbg->server_sock == -1) {
			return;
		}

		struct addrinfo hints;
		memset(&hints, 0, sizeof(hints));
		hints.ai_family = AF_INET;
		hints.ai_socktype = SOCK_STREAM;
		hints.ai_protocol = IPPROTO_TCP;

		struct addrinfo *sock_info;
		if (getaddrinfo("debug.silicondust.com", "8002", &hints, &sock_info) != 0) {
			close(dbg->server_sock);
			dbg->server_sock = -1;
			return;
		}
		if (connect(dbg->server_sock, sock_info->ai_addr, (int)sock_info->ai_addrlen) != 0) {
			freeaddrinfo(sock_info);
			close(dbg->server_sock);
			dbg->server_sock = -1;
			return;
		}
		freeaddrinfo(sock_info);
	}

	size_t length = strlen(message->buffer);	
	if (send(dbg->server_sock, (char *)message->buffer, (int)length, 0) != length) {
		close(dbg->server_sock);
		dbg->server_sock = -1;
		return;
	}
}
#endif

static bool_t hdhomerun_debug_output_message(struct hdhomerun_debug_t *dbg)
{
	pthread_mutex_lock(&dbg->queue_lock);

	struct hdhomerun_debug_message_t *message = dbg->queue_tail;
	if (!message) {
		pthread_mutex_unlock(&dbg->queue_lock);
		return FALSE;
	}

	dbg->queue_tail = message->prev;
	if (message->prev) {
		message->prev->next = NULL;
	} else {
		dbg->queue_head = NULL;
	}

	pthread_mutex_unlock(&dbg->queue_lock);

	pthread_mutex_lock(&dbg->file_lock);
	hdhomerun_debug_output_message_log_file(dbg, message);
	pthread_mutex_unlock(&dbg->file_lock);

	pthread_mutex_lock(&dbg->server_lock);
	hdhomerun_debug_output_message_support_server(dbg, message);
	pthread_mutex_unlock(&dbg->server_lock);

	free(message);

	return TRUE;
}

static THREAD_FUNC_PREFIX hdhomerun_debug_thread_execute(void *arg)
{
	struct hdhomerun_debug_t *dbg = (struct hdhomerun_debug_t *)arg;

	while (!dbg->terminate) {
		if (!hdhomerun_debug_output_message(dbg)) {
			sleep(1);
		}
	}

	return 0;
}
