/*
  dnsany -- an example of making DNS queries using libc
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
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <arpa/inet.h>
#include <resolv.h>
#include <unistd.h>
#include <stdlib.h>
#include <netdb.h>
#include <errno.h>
#include "config.h"

#ifdef TIME_WITH_SYS_TIME

#include <sys/time.h>
#include <time.h>

#else /* TIME_WITH_SYS_TIME */
#ifdef HAVE_SYS_TIME_H

#include <sys/time.h>

#else /* HAVE_SYS_TIME_H */

#include <time.h>

#endif /* HAVE_SYS_TIME_H */
#endif /* TIME_WITH_SYS_TIME */

#ifdef HAVE_NAMESER_COMPAT
#include <arpa/nameser_compat.h>
#endif /* HAVE_NAMESER_COMPAT */

extern int opterr;

#define MINVAL(a,b)             ({ typeof (a) _a = (a); typeof (b) _b = (b); _a < _b ? _a : _b; })

#define MAX_HOSTNAME            127
#define MAX_RDNS                29
#define MAX_CNAME               128

#define PROTOCOL_NAME_UDP       "udp"

#define ERROR_RES_INIT          "ERROR: unable to initialize resolver library.\n"
#define ERROR_DN_EXPAND         "ERROR: dn_expand failed for %s; this could indicate a problem with the nameserver.\n"
#define ERROR_DN_SKIPNAME       "ERROR: dn_skipname failed for %s; this could indicate a problem with the nameserver.\n"
#define ERROR_DNS_RESPONSE      "ERROR: bad or invalid dns response to %s; this could indicate a problem with the name server.\n"

#define MSG_SEARCHING           "Searching for records: %s\n"
#define MSG_SKIP                "Skipping lookup due to circular reference: %s\n"
#define MSG_FAILURE             "No records found: %s\n"

struct previous_action
  {
  char *data;
  struct previous_action *prev;
  };

/*
 * The DNS packet format is not well documented outside of the RFCs.  There is
 * almost no sample or tutorial code to be found on the internet outside of the
 * sendmail source code, which is pretty hard to read.
 *
 * Basically, each DNS packet starts with a HEADER structure, defined in
 * arpa/nameser.h (or arpa/nameser_compat.h on Linux).  Most of the time, the
 * header can be skipped.
 *
 * After the header, the nameserver returns all of the "questions" it was asked,
 * so the answers will make sense.  If you're asking more than one "question"
 * per query, this is important.  Otherwise, skip them by finding the size of
 * each question with dn_skipname() and advancing past them.  The number of
 * questions is found in the qdcount field of the header.
 *
 * Next is the answer section, which can contain many answers, though multiple
 * answers may not make much sense for all query types.  The number of answers
 * is found in the ancount field of the header.  Within each answer, the first
 * field is the name that was queried, for reference.  It can be skipped with
 * dn_skipname().
 *
 * After that comes the type in a 16 bit field, then the class in a 16 bit
 * field, then the time-to-live (TTL) in a 32 bit field, then the answer size
 * in a 16 bit field.  The type and size are important; the class and the ttl
 * can usually be ignored.  The format of the rest of the answer field is
 * different depending on the type.
 *
 * IF THE TYPE IS A:
 * The first 4 bytes are the four octets of the IP address.
 *
 * IF THE TYPE IS T_TXT:
 * The first 8 bits are an unsigned integer indicating the total length of
 * the text response.  The following bytes are the ASCII text of the response.
 *
 * IF THE TYPE IS T_PTR OR T_NS:
 * All of the bytes are the compressed name of the result.  They can be
 * decoded with dn_expand().
 *
 * IF THE TYPE IS T_CNAME:
 * All of the bytes are the compressed name of the CNAME entry.  They can be
 * decoded with dn_expand().
 *
 * IF THE TYPE IS T_MX:
 * Each answer begins with an unsigned 16 bit integer indicating the preference
 * of the mail server (lower preferences should be contacted first).  The
 * remainder of the answer is the mail server name.  It can be decoded with
 * dn_expand().
 *
 * IF THE TYPE IS T_SOA:
 * The first section of bytes are the compressed name of the primary NS server.
 * They can be decoded with dn_expand().  The second section of bytes are the
 * compressed name of the administrator's mailbox.  They can be decoded with
 * dn_expand().  After the end of the mailbox data, five 32 bit integers give
 * the serial number, the refresh interval, the retry interval, the expiration
 * limit and the minimum time to live, in that order.
 *
 * SEE ALSO:
 *   RFC 1035
 *   http://www.zytrax.com/books/dns/ch15/
 *   "DNS and BIND" from O'Reilly
 */
void dns_any(char *target_name, struct previous_action *history, int verbose)
  {
  int i;
  unsigned char answer[PACKETSZ];
  unsigned char host[MAX_HOSTNAME + 1];
  unsigned char *answer_ptr;
  unsigned char *answer_start;
  unsigned char *cname_ptr[MAX_CNAME];
  int num_cnames;
  int answer_length;
  int size;
  int type;
  int preference;
  long serial;
  long refresh;
  long retry;
  long expiration;
  long ttl;
  int txt_length;
  int num_questions;
  int num_answers;
  int exit_loop;
  struct previous_action current_lookup;
  struct previous_action *tmp_lookup;
  HEADER *tmp_header;

  memset(answer, 0, PACKETSZ);

  if (target_name != NULL)
    {
    if (verbose)
      printf(MSG_SEARCHING, target_name);

    if ((answer_length = res_query(target_name, C_IN, T_ANY, answer, PACKETSZ)) >= 0)
      {
      answer_ptr = answer + sizeof(HEADER);

      // Skip the questions
      tmp_header = (HEADER *)&answer;
      num_questions = ntohs((unsigned short)tmp_header->qdcount);
      for (i = 0; i < num_questions; i++)
        if ((size = dn_skipname(answer_ptr, answer + answer_length)) >= 0)
          answer_ptr += size + QFIXEDSZ;
        else
          break;

      if (i == num_questions)
        {
        num_answers = ntohs((unsigned short)tmp_header->ancount);
        num_cnames = 0;
        answer_start = answer_ptr;

        exit_loop = 0;
        for (i = 0; (i < num_answers) && !exit_loop; i++)
          if ((size = dn_skipname(answer_ptr, answer + answer_length)) >= 0)
            {
            answer_ptr += size;
            GETSHORT(type, answer_ptr);
            answer_ptr += INT16SZ; // class
            answer_ptr += INT32SZ; // ttl
            answer_ptr += INT16SZ; // size

            switch (type)
              {
              case T_A:
                printf("A:\t%d.%d.%d.%d\n", answer_ptr[0], answer_ptr[1], answer_ptr[2], answer_ptr[3]);
                answer_ptr += 4;

                break;
              case T_MX:
                GETSHORT(preference, answer_ptr);
                if ((size = dn_expand(answer, answer + answer_length, answer_ptr, (char *)host, MAX_HOSTNAME)) >= 0)
                  {
                  printf("MX:\t%d\t%s\n", preference, host);
                  answer_ptr += size;
                  }
                else
                  {
                  printf(ERROR_DN_EXPAND, target_name);
                  exit_loop = 1;
                  }

                break;
              case T_NS:
                if ((size = dn_expand(answer, answer + answer_length, answer_ptr, (char *)host, MAX_HOSTNAME)) >= 0)
                  {
                  printf("NS:\t%s\n", host);
                  answer_ptr += size;
                  }
                else
                  {
                  printf(ERROR_DNS_RESPONSE, target_name);
                  exit_loop = 1;
                  }

                break;
              case T_PTR:
                if ((size = dn_expand(answer, answer + answer_length, answer_ptr, (char *)host, MAX_HOSTNAME)) >= 0)
                  {
                  printf("PTR:\t%s\n", host);
                  answer_ptr += size;
                  }
                else
                  {
                  printf(ERROR_DNS_RESPONSE, target_name);
                  exit_loop = 1;
                  }

                break;
              case T_SOA:
                if ((size = dn_expand(answer, answer + answer_length, answer_ptr, (char *)host, MAX_HOSTNAME)) >= 0)
                  {
                  printf("SOA:\tNS:\t\t%s\n", host);
                  answer_ptr += size;

                  if ((size = dn_expand(answer, answer + answer_length, answer_ptr, (char *)host, MAX_HOSTNAME)) >= 0)
                    {
                    printf("\tADMIN:\t\t%s\n", host);
                    answer_ptr += size;

                    GETLONG(serial, answer_ptr);
                    printf("\tSERIAL:\t\t%lu\n", serial);

                    GETLONG(refresh, answer_ptr);
                    printf("\tREFRESH:\t%lu\n", refresh);

                    GETLONG(retry, answer_ptr);
                    printf("\tRETRY:\t\t%lu\n", retry);

                    GETLONG(expiration, answer_ptr);
                    printf("\tEXPIRATION:\t%lu\n", expiration);

                    GETLONG(ttl, answer_ptr);
                    printf("\tTTL:\t\t%lu\n", ttl);
                    }
                  else
                    {
                    printf(ERROR_DNS_RESPONSE, target_name);
                    exit_loop = 1;
                    }
                  }
                else
                  {
                  printf(ERROR_DNS_RESPONSE, target_name);
                  exit_loop = 1;
                  }

                break;
              case T_TXT:
                txt_length = (unsigned char)*answer_ptr;
                answer_ptr++;

                if ((txt_length >= 0) &&
                    (txt_length < size))
                  {
                  printf("TXT:\t%.*s\n", txt_length, answer_ptr);
                  answer_ptr += size - 1;
                  }
                else
                  {
                  printf(ERROR_DNS_RESPONSE, target_name);
                  exit_loop = 1;
                  }

                break;
              case T_CNAME:
                cname_ptr[num_cnames] = answer_ptr;
                num_cnames++;

                if ((size = dn_expand(answer, answer + answer_length, answer_ptr, (char *)host, MAX_HOSTNAME)) >= 0)
                  {
                  printf("CNAME:\t%s\n", host);
                  answer_ptr += size;
                  }
                else
                  {
                  printf(ERROR_DN_EXPAND, target_name);
                  exit_loop = 1;
                  }

                break;
              }
            }
          else
            {
            printf(ERROR_DN_SKIPNAME, target_name);
            break;
            }

        for (i = 0; i < num_cnames; i++)
          if ((size = dn_expand(answer, answer + answer_length, cname_ptr[i], (char *)host, MAX_HOSTNAME)) >= 0)
            {
            current_lookup.data = target_name;
            current_lookup.prev = history;

            tmp_lookup = &current_lookup;
            while (tmp_lookup != NULL)
              if (strcasecmp((char *)host, tmp_lookup->data) == 0)
                break;
              else
                tmp_lookup = tmp_lookup->prev;

            if (tmp_lookup == NULL) 
              {
              printf("\n");
              dns_any((char *)host, &current_lookup, verbose);
              }
            answer_ptr += size;
            }
          else
            {
            printf(ERROR_DN_EXPAND, target_name);
            break;
            }
        }
      else
        printf(ERROR_DN_SKIPNAME, target_name);
      }
    else if (verbose)
      printf(MSG_FAILURE, target_name);
    }

  return;
  }

void usage()
  {
  printf(
    PACKAGE_NAME " " PACKAGE_VERSION " (C)2012 Sam Clippinger, " PACKAGE_BUGREPORT "\n"
    "http://www.spamdyke.org/\n"
    "\n"
    "USAGE: dnsany_libc [ -v ] FQDN [ FQDN ... ]\n"
    "\n"
    "Performs a DNS lookup for any records associated with FQDN and prints the results.\n"
    "\n"
    "-v\n"
    "  Give more verbose output\n"
    );

  return;
  }

int main(int argc, char *argv[])
  {
  int i;
  int verbose;
  int opt;
  int error;

  opterr = 0;
  verbose = 0;
  error = 0;

  while ((opt = getopt(argc, argv, "v")) != -1)
    switch (opt)
      {
      case 'v':
        verbose = 1;
        break;
      default:
        usage();
        error = 1;
        break;
      }

  if (!error)
    {
    if ((argc - optind) > 0)
      for (i = optind; i < argc; i++)
        dns_any(argv[i], NULL, verbose);
    else
      usage();
    }

  return(0);
  }
