/* Copyright? Nah public domain! BTW I created it: Han Boetes <han@boetes.org> */

/*
 * This thingie prints the number of emails and the date together with some
 * color strings that are recognized by tmux.
 */
#include <stdio.h>
#include <dirent.h>
#include <err.h>
#include <errno.h>
#include <stdlib.h>

#include <time.h>
#define SLENGTH 40
#define MAILPATH "/home/han/Mail/Maildir/new/"

int
main(void) {

        char  mailpath[] = MAILPATH;
        DIR  *dirp;
        uint  i = 0;
        struct dirent  *dp;
        char nowstr[SLENGTH];
        time_t nowbin;
        const struct tm *nowstruct;

        /* Open the directory */
        if ((dirp = opendir(mailpath)) == NULL)
                err(1, "%s", mailpath);
        /* Count the number of files in the directory */
        while ((dp = readdir(dirp)) != NULL) {
                /* Step over . files such as . and .. , prolly not required for
                 * the rest... */
                if (dp->d_name[0] == '.')
                        continue;
                /* Make sure i never gets bigger than 9 since that would clutter
                 * the statusbar. So interpret 9 @ as many mails. */
                /* if (i == 9) */
                /*      break; */
                i++;
        }
        closedir(dirp);

        if (i > 0) {
                /* Print color codes and number of new mails */
                printf ("%s%i%s", "#[fg=blue]", i, " #[fg=cyan]");
                /* Print a '@' for each new email  */
                /* for (;i > 0; i--) */
                /*      putchar('@'); */
        }

        /* Print the time and date. */
        time(&nowbin);
        nowstruct = localtime(&nowbin);
        strftime(nowstr, SLENGTH, "%a %b %d %H:%M:%S", nowstruct);
        printf("%s\n", nowstr);

        exit(0);
}
