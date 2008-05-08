/*
 * hdhomerun_debug.h
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

#ifdef __cplusplus
extern "C" {
#endif

struct hdhomerun_debug_t;

extern struct hdhomerun_debug_t *hdhomerun_debug_create(void);
extern void hdhomerun_debug_destroy(struct hdhomerun_debug_t *dbg);

extern void hdhomerun_debug_enable_log_file(struct hdhomerun_debug_t *dbg, char *filename);
extern void hdhomerun_debug_disable_log_file(struct hdhomerun_debug_t *dbg);
extern void hdhomerun_debug_enable_support_server(struct hdhomerun_debug_t *dbg);
extern void hdhomerun_debug_disable_support_server(struct hdhomerun_debug_t *dbg);

extern bool_t hdhomerun_debug_enabled(struct hdhomerun_debug_t *dbg);

extern void hdhomerun_debug_printf(struct hdhomerun_debug_t *dbg, const char *fmt, ...);
extern void hdhomerun_debug_vprintf(struct hdhomerun_debug_t *dbg, const char *fmt, va_list args);

#ifdef __cplusplus
}
#endif
