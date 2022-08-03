/*
 * slowcat.c - slow down the display of a file
 * copyright (c) 2001,2002,2007  dave w capella   All Rights Reserved
 *
 * distributed under the terms of the GNU Public license
 *
 * There is NO WARRANTY, and NO SUPPORT WHATSOEVER.
 *
 * building: make slowcat && mv slowcat $HOME/bin
 * (assuming that you have a personal bin directory)
 *
 * usage: slowcat [-l (line buffering)] [-d usecs] [-D (debug)] filename
 * where usecs is the number of micro-seconds to delay.
 *
 * feedback welcome. enjoy!
 * ...dave
 *
 *
 * 09/24/07 - modifications to include nanosleep, brian at landsberger.com
 * 08/23/18 - added some options and fixed nanosleep() values
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>

int debug = 0;

int main(int argc, char ** argv)
{
        int c;
        uint32_t usecs = 5000, s;
        FILE * fp;
        char * fnam = 0;
        struct timespec ts;
        int lineBuffering = 0;


        for (int argIndex = 1; argIndex < argc; argIndex++) {
                if (!strncmp(argv[argIndex], "-d", 2) && argIndex + 1 < argc) {
                        usecs = strtoul(argv[++argIndex], NULL, 10);
                        if (usecs <= 0 || usecs > 1000000) {
                                usecs = 1;
                        }
                }
                if (!strncmp(argv[argIndex], "-l", 2)) {
                        lineBuffering = 1;
                }

                if (!strncmp(argv[argIndex], "-D", 2)) {
                        debug = 1;
                }

                if (argIndex == argc-1) {
                        fnam = argv[argIndex];
                }
        }

        if (lineBuffering) {
                setlinebuf(stdout);
        } else {
                setvbuf(stdout, NULL, _IONBF, 0);
        }

        if (0 == fnam) {
                fprintf(stderr, "usage: %s [-l (line buffering)] [-d usecs] [-D (debug)] filename\n", argv[0]);
                exit(1);
        }

        /* set timespec */
        ts.tv_sec = 0;
        ts.tv_nsec = usecs * 1000;

        if (argc == 2 ) {
                fnam = argv[1];
        }
        fp = fopen(fnam, "r");
        if (fp == NULL) {
                fprintf(stderr, "usage: %s [-d usecs] filename\n", argv[0]);
                exit(2);
        }

        while( (c = fgetc(fp)) != EOF) {
                putchar(c);

                if (debug) {
                        fprintf(stderr, "sleeping using nanosleep\n");
                }
                nanosleep(&ts, NULL);
        }

        fclose(fp);
        return (0);
}
