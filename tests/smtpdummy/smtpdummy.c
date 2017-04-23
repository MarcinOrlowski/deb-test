/*
  smtpdummy -- a simple program for simulating a slow SMTP server
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
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/select.h>
#include <unistd.h>
#include <errno.h>

#define MAX_BUF                         4095
#define STRLEN(X)                       (sizeof(X) - 1)
#define _STRINGIFY(X)                   #X
#define STRINGIFY(X)                    _STRINGIFY(X)

#define STDIN_FD                        0
#define STDOUT_FD                       1

#define TYPE_AUTH_PLAIN                 0
#define TYPE_AUTH_LOGIN                 1
#define TYPE_AUTH_CRAM_MD5              2

#define GREETING_BANNER                 "220 smtpdummy ESMTP\r\n"
#define COMMAND_HELO                    "HELO"
#define RESPONSE_HELO                   "250 HELO received\r\n"
#define COMMAND_EHLO                    "EHLO"
#define RESPONSE_EHLO_AUTH              "250-AUTH LOGIN PLAIN CRAM-MD5\r\n250-AUTH=LOGIN PLAIN CRAM-MD5\r\n250-PIPELINING\r\n250 8BITMIME\r\n"
#define RESPONSE_EHLO_NO_AUTH           "250-X-NOTHING\r\n250-PIPELINING\r\n250 8BITMIME\r\n"
#define COMMAND_AUTH_LOGIN              "AUTH LOGIN"
#define RESPONSE_AUTH_LOGIN_1           "334 VXNlcm5hbWU6\r\n"
#define RESPONSE_AUTH_LOGIN_2           "334 UGFzc3dvcmQ6\r\n"
#define COMMAND_AUTH_PLAIN              "AUTH PLAIN"
#define RESPONSE_AUTH_PLAIN             "334 AUTH PLAIN received\r\n"
#define COMMAND_AUTH_CRAM_MD5           "AUTH CRAM-MD5"
#define RESPONSE_AUTH_CRAM_MD5          "334 AUTH-CRAM-MD5-received\r\n"
#define RESPONSE_AUTH                   "235 AUTH success\r\n"
#define RESPONSE_AUTH_REJECT            "554 AUTH failure\r\n"
#define COMMAND_MAIL                    "MAIL"
#define RESPONSE_MAIL                   "250 MAIL received\r\n"
#define COMMAND_RCPT                    "RCPT"
#define RESPONSE_RCPT                   "250 RCPT received\r\n"
#define RESPONSE_RCPT_REJECT            "421 RCPT rejected\r\n"
#define COMMAND_RSET                    "RSET"
#define RESPONSE_RSET                   "250 RSET received\r\n"
#define COMMAND_DATA                    "DATA"
#define RESPONSE_DATA                   "354 DATA received\r\n"
#define COMMAND_DATA_END                "."
#define RESPONSE_DATA_END               "250 DATA END received\r\n"
#define RESPONSE_DATA_REJECT            "554 DATA END rejected\r\n"
#define COMMAND_QUIT                    "QUIT"
#define RESPONSE_QUIT                   "221 QUIT received\r\n"
#define RESPONSE_ERROR                  "554 error: %.*s\r\n"

void usage()
  {
  printf(
    "USAGE: smtpdummy [ -aDlLR ] [ -T IDLE_TIMEOUT_SECS ] [ -h HELO_DELAY_SECS ] [ -A AUTH_DELAY_SECS ] [ -m MAIL_DELAY_SECS ] [ -r RCPT_DELAY_SECS ] [ -d DATA_DELAY_SECS ] [ -e DATA_END_DELAY_SECS ] [ -q QUIT_DELAY_SECS ] [ -o FILENAME ]\n"
    "\n"
    "-a\n"
    "  Advertise authentication in response to EHLO\n"
    "-A SECS\n"
    "  Wait SECS seconds before responding to AUTH\n"
    "-d SECS\n"
    "  Wait SECS seconds before responding to DATA\n"
    "-D\n"
    "  Reject message content with an error\n"
    "-e SECS\n"
    "  Wait SECS seconds before responding to the end of the message\n"
    "-h SECS\n"
    "  Wait SECS seconds before responding to HELO\n"
    "-l\n"
    "  Process authentication and return success\n"
    "-L\n"
    "  Process authentication and return failure\n"
    "-m SECS\n"
    "  Wait SECS seconds before responding to MAIL\n"
    "-o FILENAME\n"
    "  Save message content into FILENAME\n"
    "-q SECS\n"
    "  Wait SECS seconds before responding to QUIT\n"
    "-r SECS\n"
    "  Wait SECS seconds before responding to RCPT\n"
    "-R\n"
    "  Reject all recipients with an error\n"
    "-T SECS\n"
    "  Quit after SECS seconds of inactivity (default: no timeout)\n"
    );
  exit(0);
  }

int main(int argc, char *argv[])
  {
  int return_value;
  int continue_looping;
  int inside_data;
  int opt;
  int read_result;
  char tmp_buf[MAX_BUF + 1];
  int strlen_buf;
  int strlen_trim;
  char *start_buf;
  char *next_terminator;
  int tmp_int;
  int idle_timeout_secs;
  int delay_helo;
  int delay_auth;
  int delay_mail;
  int delay_rcpt;
  int delay_data;
  int delay_data_end;
  int delay_quit;
  char *output_filename;
  FILE *output_file;
  struct timeval tmp_timeval;
  fd_set read_fdset;
  int ehlo_auth;
  int reject_all;
  int reject_message;
  int auth_success;
  int auth_step;
  int auth_type;
  char tmp_format[MAX_BUF + 1];
  int strlen_tmp_format;

  return_value = 0;
  idle_timeout_secs = 0;
  delay_helo = 0;
  delay_auth = 0;
  delay_mail = 0;
  delay_rcpt = 0;
  delay_data = 0;
  delay_data_end = 0;
  delay_quit = 0;
  output_filename = NULL;
  output_file = NULL;
  ehlo_auth = 0;
  reject_all = 0;
  reject_message = 0;
  auth_success = 0;
  auth_step = 0;
  auth_type = 0;

  while ((opt = getopt(argc, argv, "aA:d:De:h:lLm:o:q:r:RT:")) != -1)
    {
    switch (opt)
      {
      case 'a':
        ehlo_auth = 1;
        break;
      case 'A':
        if ((sscanf(optarg, "%d", &tmp_int) == 1) &&
            (tmp_int >= 0))
          delay_auth = tmp_int;

        break;
      case 'd':
        if ((sscanf(optarg, "%d", &tmp_int) == 1) &&
            (tmp_int >= 0))
          delay_data = tmp_int;

        break;
      case 'D':
        reject_message = 1;
        break;
      case 'e':
        if ((sscanf(optarg, "%d", &tmp_int) == 1) &&
            (tmp_int >= 0))
          delay_data_end = tmp_int;

        break;
      case 'h':
        if ((sscanf(optarg, "%d", &tmp_int) == 1) &&
            (tmp_int >= 0))
          delay_helo = tmp_int;

        break;
      case 'l':
        auth_success = 1;
        break;
      case 'L':
        auth_success = 0;
        break;
      case 'm':
        if ((sscanf(optarg, "%d", &tmp_int) == 1) &&
            (tmp_int >= 0))
          delay_mail = tmp_int;

        break;
      case 'o':
        output_filename = optarg;
        break;
      case 'q':
        if ((sscanf(optarg, "%d", &tmp_int) == 1) &&
            (tmp_int >= 0))
          delay_quit = tmp_int;

        break;
      case 'r':
        if ((sscanf(optarg, "%d", &tmp_int) == 1) &&
            (tmp_int >= 0))
          delay_rcpt = tmp_int;

        break;
      case 'T':
        if ((sscanf(optarg, "%d", &tmp_int) == 1) &&
            (tmp_int >= 0))
          idle_timeout_secs = tmp_int;

        break;
      case 'R':
        reject_all = 1;
        break;
      default:
        usage();
        break;
      }
    }

  if (argv[optind] != NULL)
    usage();

  if ((output_filename != NULL) &&
      ((output_file = fopen(output_filename, "w")) == NULL))
    fprintf(stderr, "ERROR: unable to open %s: %s\n", output_filename, strerror(errno));

  write(STDOUT_FD, GREETING_BANNER, STRLEN(GREETING_BANNER));

  continue_looping = 1;
  inside_data = 0;
  start_buf = tmp_buf;
  strlen_buf = 0;

  while (continue_looping)
    {
    if (idle_timeout_secs > 0)
      {
      tmp_timeval.tv_sec = idle_timeout_secs;
      tmp_timeval.tv_usec = 0;

      FD_ZERO(&read_fdset);
      FD_SET(STDIN_FD, &read_fdset);

      if (select(STDIN_FD + 1, &read_fdset, NULL, NULL, &tmp_timeval) <= 0)
        {
        return_value = 111;
        break;
        }
      }

    if ((read_result = read(STDIN_FD, start_buf + strlen_buf, MAX_BUF - (start_buf - tmp_buf) - strlen_buf)) > 0)
      {
      strlen_buf += read_result;
      start_buf[strlen_buf] = '\0';

      while (((next_terminator = memchr(start_buf, '\n', strlen_buf)) != NULL) ||
             (strlen_buf == MAX_BUF))
        {
        if (next_terminator != NULL)
          {
          strlen_trim = next_terminator - start_buf;
          if ((strlen_buf > 1) &&
              (next_terminator[-1] == '\r'))
            strlen_trim--;

          next_terminator++;
          }
        else
          next_terminator = start_buf + strlen_buf;

        if (!inside_data)
          {
          if (auth_step > 0)
            switch (auth_type)
              {
              case TYPE_AUTH_LOGIN:
                if (auth_step == 1)
                  {
                  sleep(delay_auth);
                  write(STDOUT_FD, RESPONSE_AUTH_LOGIN_2, STRLEN(RESPONSE_AUTH_LOGIN_2));
                  auth_step = 2;
                  }
                else if (auth_step == 2)
                  {
                  sleep(delay_auth);

                  if (auth_success)
                    write(STDOUT_FD, RESPONSE_AUTH, STRLEN(RESPONSE_AUTH));
                  else
                    write(STDOUT_FD, RESPONSE_AUTH_REJECT, STRLEN(RESPONSE_AUTH_REJECT));

                  auth_step = 0;
                  }

                break;
              case TYPE_AUTH_PLAIN:
              case TYPE_AUTH_CRAM_MD5:
                sleep(delay_auth);

                if (auth_success)
                  write(STDOUT_FD, RESPONSE_AUTH, STRLEN(RESPONSE_AUTH));
                else
                  write(STDOUT_FD, RESPONSE_AUTH_REJECT, STRLEN(RESPONSE_AUTH_REJECT));

                auth_step = 0;

                break;
              }
          else if (((strlen_trim == STRLEN(COMMAND_HELO)) ||
                    ((strlen_trim > STRLEN(COMMAND_HELO)) &&
                     isspace(start_buf[STRLEN(COMMAND_HELO)]))) &&
                   (strncasecmp(start_buf, COMMAND_HELO, STRLEN(COMMAND_HELO)) == 0))
            {
            sleep(delay_helo);
            write(STDOUT_FD, RESPONSE_HELO, STRLEN(RESPONSE_HELO));
            }
          else if (((strlen_trim == STRLEN(COMMAND_EHLO)) ||
                    ((strlen_trim > STRLEN(COMMAND_EHLO)) &&
                     isspace(start_buf[STRLEN(COMMAND_EHLO)]))) &&
                   (strncasecmp(start_buf, COMMAND_EHLO, STRLEN(COMMAND_EHLO)) == 0))
            {
            sleep(delay_helo);

            if (ehlo_auth)
              write(STDOUT_FD, RESPONSE_EHLO_AUTH, STRLEN(RESPONSE_EHLO_AUTH));
            else
              write(STDOUT_FD, RESPONSE_EHLO_NO_AUTH, STRLEN(RESPONSE_EHLO_NO_AUTH));
            }
          else if (((strlen_trim == STRLEN(COMMAND_AUTH_LOGIN)) ||
                    ((strlen_trim > STRLEN(COMMAND_AUTH_LOGIN)) &&
                     isspace(start_buf[STRLEN(COMMAND_AUTH_LOGIN)]))) &&
                   (strncasecmp(start_buf, COMMAND_AUTH_LOGIN, STRLEN(COMMAND_AUTH_LOGIN)) == 0))
            {
            sleep(delay_auth);
            write(STDOUT_FD, RESPONSE_AUTH_LOGIN_1, STRLEN(RESPONSE_AUTH_LOGIN_1));
            auth_type = TYPE_AUTH_LOGIN;
            auth_step = 1;
            }
          else if (((strlen_trim == STRLEN(COMMAND_AUTH_PLAIN)) ||
                    ((strlen_trim > STRLEN(COMMAND_AUTH_PLAIN)) &&
                     isspace(start_buf[STRLEN(COMMAND_AUTH_PLAIN)]))) &&
                   (strncasecmp(start_buf, COMMAND_AUTH_PLAIN, STRLEN(COMMAND_AUTH_PLAIN)) == 0))
            {
            sleep(delay_auth);
            write(STDOUT_FD, RESPONSE_AUTH_PLAIN, STRLEN(RESPONSE_AUTH_PLAIN));
            auth_type = TYPE_AUTH_PLAIN;
            auth_step = 1;
            }
          else if (((strlen_trim == STRLEN(COMMAND_AUTH_CRAM_MD5)) ||
                    ((strlen_trim > STRLEN(COMMAND_AUTH_CRAM_MD5)) &&
                     isspace(start_buf[STRLEN(COMMAND_AUTH_CRAM_MD5)]))) &&
                   (strncasecmp(start_buf, COMMAND_AUTH_CRAM_MD5, STRLEN(COMMAND_AUTH_CRAM_MD5)) == 0))
            {
            sleep(delay_auth);
            write(STDOUT_FD, RESPONSE_AUTH_CRAM_MD5, STRLEN(RESPONSE_AUTH_CRAM_MD5));
            auth_type = TYPE_AUTH_CRAM_MD5;
            auth_step = 1;
            }
          else if (((strlen_trim == STRLEN(COMMAND_MAIL)) ||
                    ((strlen_trim > STRLEN(COMMAND_MAIL)) &&
                     isspace(start_buf[STRLEN(COMMAND_MAIL)]))) &&
                   (strncasecmp(start_buf, COMMAND_MAIL, STRLEN(COMMAND_MAIL)) == 0))
            {
            sleep(delay_mail);
            write(STDOUT_FD, RESPONSE_MAIL, STRLEN(RESPONSE_MAIL));
            }
          else if (((strlen_trim == STRLEN(COMMAND_RCPT)) ||
                    ((strlen_trim > STRLEN(COMMAND_RCPT)) &&
                     isspace(start_buf[STRLEN(COMMAND_RCPT)]))) &&
                   (strncasecmp(start_buf, COMMAND_RCPT, STRLEN(COMMAND_RCPT)) == 0))
            {
            sleep(delay_rcpt);

            if (reject_all)
              write(STDOUT_FD, RESPONSE_RCPT_REJECT, STRLEN(RESPONSE_RCPT_REJECT));
            else
              write(STDOUT_FD, RESPONSE_RCPT, STRLEN(RESPONSE_RCPT));
            }
          else if (((strlen_trim == STRLEN(COMMAND_RSET)) ||
                    ((strlen_trim > STRLEN(COMMAND_RSET)) &&
                     isspace(start_buf[STRLEN(COMMAND_RSET)]))) &&
                   (strncasecmp(start_buf, COMMAND_RSET, STRLEN(COMMAND_RSET)) == 0))
            {
            write(STDOUT_FD, RESPONSE_RSET, STRLEN(RESPONSE_RSET));
            }
          else if (((strlen_trim == STRLEN(COMMAND_DATA)) ||
                    ((strlen_trim > STRLEN(COMMAND_DATA)) &&
                     isspace(start_buf[STRLEN(COMMAND_DATA)]))) &&
                   (strncasecmp(start_buf, COMMAND_DATA, STRLEN(COMMAND_DATA)) == 0))
            {
            sleep(delay_data);
            write(STDOUT_FD, RESPONSE_DATA, STRLEN(RESPONSE_DATA));
            inside_data = 1;
            }
          else if (((strlen_trim == STRLEN(COMMAND_QUIT)) ||
                    ((strlen_trim > STRLEN(COMMAND_QUIT)) &&
                     isspace(start_buf[STRLEN(COMMAND_QUIT)]))) &&
                   (strncasecmp(start_buf, COMMAND_QUIT, STRLEN(COMMAND_QUIT)) == 0))
            {
            sleep(delay_quit);
            write(STDOUT_FD, RESPONSE_QUIT, STRLEN(RESPONSE_QUIT));
            continue_looping = 0;
            }
          else
            {
            snprintf(tmp_format, MAX_BUF, RESPONSE_ERROR "%n", strlen_trim, start_buf, &strlen_tmp_format);
            write(STDOUT_FD, tmp_format, strlen_tmp_format);
            }
          }
        else
          if ((strlen_trim == STRLEN(COMMAND_DATA_END)) &&
              (strncasecmp(start_buf, COMMAND_DATA_END, STRLEN(COMMAND_DATA_END)) == 0))
            {
            sleep(delay_data_end);

            if (!reject_message)
              write(STDOUT_FD, RESPONSE_DATA_END, STRLEN(RESPONSE_DATA_END));
            else
              write(STDOUT_FD, RESPONSE_DATA_REJECT, STRLEN(RESPONSE_DATA_REJECT));

            inside_data = 0;
            }
          else if (output_file != NULL)
            {
            fprintf(output_file, "%.*s", (int)(next_terminator - start_buf), start_buf);
            fflush(NULL);
            }

        strlen_buf -= next_terminator - start_buf;
        start_buf = next_terminator;
        }

      if (tmp_buf != start_buf)
        {
        memmove(tmp_buf, start_buf, strlen_buf);
        start_buf = tmp_buf;
        }
      }
    else
      continue_looping = 0;
    }

  if (output_file != NULL)
    {
    fclose(output_file);
    output_file = NULL;
    }

  return(return_value);
  }
