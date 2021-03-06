/*
  spamdyke -- a filter for stopping spam at connection time.
  Copyright (C) 2012 Sam Clippinger (samc (at) silence (dot) org)

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License version 2 as
  published by the Free Software Foundation.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
#ifndef LOG_H
#define LOG_H

#include "spamdyke.h"

int output_writeln(struct filter_settings *current_settings, int action, int target_fd, char *data, int data_length);
void spamdyke_log(struct filter_settings *current_settings, int target_level, int output_to_full_log, char *format, ...);
char *canonicalize_log_text(char *target_buf, int strlen_target_buf, char *input_text, int strlen_input_text);

#endif /* LOG_H */
