/*
 * hdhomerun_channelscan.c
 *
 * Copyright © 2007 Silicondust Engineering Ltd. <www.silicondust.com>.
 *
 * This library is free software; you can redistribute it and/or 
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "hdhomerun_os.h"
#include "hdhomerun_pkt.h"
#include "hdhomerun_debug.h"
#include "hdhomerun_control.h"
#include "hdhomerun_device.h"
#include "hdhomerun_channels.h"
#include "hdhomerun_channelscan.h"

static int channelscan_execute_find_lock_internal(struct hdhomerun_device_t *hd, uint32_t frequency, struct hdhomerun_tuner_status_t *status)
{
	char channel_str[64];

	/* Set auto channel. */
	sprintf(channel_str, "auto:%ld", (unsigned long)frequency);
	int ret = hdhomerun_device_set_tuner_channel(hd, channel_str);
	if (ret <= 0) {
		return ret;
	}

	/* Wait for lock. */
	ret = hdhomerun_device_wait_for_lock(hd, status);
	if (ret <= 0) {
		return ret;
	}
	if (status->lock_supported || status->lock_unsupported) {
		return 1;
	}

	return 1;
}

static int channelscan_execute_find_lock(struct hdhomerun_device_t *hd, uint32_t frequency, struct hdhomerun_tuner_status_t *status)
{
	int ret = channelscan_execute_find_lock_internal(hd, frequency, status);
	if (ret <= 0) {
		return ret;
	}

	if (!status->lock_supported) {
		return 1;
	}

	int i;
	for (i = 0; i < 5 * 4; i++) {
		usleep(250000);

		ret = hdhomerun_device_get_tuner_status(hd, status);
		if (ret <= 0) {
			return ret;
		}

		if (status->symbol_error_quality == 100) {
			break;
		}
	}

	return 1;
}

static int channelscan_execute_find_programs(struct hdhomerun_device_t *hd, char **pstreaminfo)
{
	*pstreaminfo = NULL;

	char *streaminfo;
	int ret = hdhomerun_device_get_tuner_streaminfo(hd, &streaminfo);
	if (ret <= 0) {
		return ret;
	}

	char *last_streaminfo = strdup(streaminfo);
	if (!last_streaminfo) {
		return -1;
	}

	int same = 0;
	int i;
	for (i = 0; i < 5 * 4; i++) {
		usleep(250000);

		ret = hdhomerun_device_get_tuner_streaminfo(hd, &streaminfo);
		if (ret <= 0) {
			free(last_streaminfo);
			return ret;
		}

		if (strcmp(streaminfo, last_streaminfo) != 0) {
			free(last_streaminfo);
			last_streaminfo = strdup(streaminfo);
			if (!last_streaminfo) {
				return -1;
			}
			same = 0;
			continue;
		}

		same++;
		if (same >= 8) {
			break;
		}
	}

	*pstreaminfo = last_streaminfo;
	return 1;
}

static int channelscan_execute_callback(channelscan_callback_t callback, va_list callback_ap, const char *type, const char *str)
{
	if (!callback) {
		return 1;
	}
	
	va_list ap;
	va_copy(ap, callback_ap);
	int ret = callback(ap, type, str);
	va_end(ap);

	return ret;
}

static int channelscan_execute_internal(struct hdhomerun_device_t *hd, uint32_t channel_map, struct hdhomerun_channel_entry_t **pentry, channelscan_callback_t callback, va_list callback_ap)
{
	struct hdhomerun_channel_entry_t *entry = *pentry;
	uint32_t frequency = hdhomerun_channel_entry_frequency(entry);
	char buffer[256];
	int ret;

	/* Combine channels with same frequency. */
	char *ptr = buffer;
	sprintf(ptr, "%ld (", (unsigned long)frequency);
	ptr = strchr(ptr, 0);
	while (1) {
		const char *name = hdhomerun_channel_entry_name(entry);
		strcpy(ptr, name);
		ptr = strchr(ptr, 0);

		entry = hdhomerun_channel_list_next(channel_map, entry);
		if (!entry) {
			break;
		}
		if (hdhomerun_channel_entry_frequency(entry) != frequency) {
			break;
		}

		sprintf(ptr, ", ");
		ptr = strchr(ptr, 0);
	}
	sprintf(ptr, ")");
	*pentry = entry;

	ret = channelscan_execute_callback(callback, callback_ap, "SCANNING", buffer);
	if (ret <= 0) {
		return ret;
	}

	/* Find lock. */
	struct hdhomerun_tuner_status_t status;
	ret = channelscan_execute_find_lock(hd, frequency, &status);
	if (ret <= 0) {
		return ret;
	}

	ptr = buffer;
	sprintf(ptr, "%s (ss=%u snq=%u seq=%u)", status.lock_str, status.signal_strength, status.signal_to_noise_quality, status.symbol_error_quality);

	ret = channelscan_execute_callback(callback, callback_ap, "LOCK", buffer);
	if (ret <= 0) {
		return ret;
	}

	if (!status.lock_supported) {
		return 1;
	}

	/* Detect programs. */
	char *streaminfo = NULL;
	ret = channelscan_execute_find_programs(hd, &streaminfo);
	if (ret <= 0) {
		return ret;
	}

	ptr = streaminfo;
	while (1) {
		char *end = strchr(ptr, '\n');
		if (!end) {
			break;
		}

		*end++ = 0;

		ret = channelscan_execute_callback(callback, callback_ap, "PROGRAM", ptr);
		if (ret <= 0) {
			free(streaminfo);
			return ret;
		}

		ptr = end;
	}

	free(streaminfo);

	/* Complete. */
	return 1;
}

int channelscan_execute_single(struct hdhomerun_device_t *hd, uint32_t channel_map, struct hdhomerun_channel_entry_t **pentry, channelscan_callback_t callback, ...)
{
	if (!*pentry) {
		*pentry = hdhomerun_channel_list_first(channel_map);
	}

	va_list callback_ap;
	va_start(callback_ap, callback);

	int result = channelscan_execute_internal(hd, channel_map, pentry, callback, callback_ap);

	va_end(callback_ap);
	return result;
}

int channelscan_execute_all(struct hdhomerun_device_t *hd, uint32_t channel_map, channelscan_callback_t callback, ...)
{
	va_list callback_ap;
	va_start(callback_ap, callback);

	int result = 0;
	struct hdhomerun_channel_entry_t *entry = hdhomerun_channel_list_first(channel_map);
	while (entry) {
		result = channelscan_execute_internal(hd, channel_map, &entry, callback, callback_ap);
		if (result <= 0) {
			break;
		}
	}

	va_end(callback_ap);
	return result;
}
