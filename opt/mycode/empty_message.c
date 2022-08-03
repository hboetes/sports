/*
 * This is some trivial code to detect empty email messages.
 *
 * Pipe a message through the resulting binary and then check the
 * returncode; ie:
 *
 *   cat message| empty_message|| echo this is an emtpy message
 *
 * or with maildrop:
 *
 * `empty_message`
 * if ($RETURNCODE == 1)
 *   to $DEFAULT/empty
 *
 * This is to replace the shell solution:
 *
 *   sed -e '1,/^$/ d'|wc -l
 *
 * which works fine as well but uses much more systemresources.
 *
 * Released in PUBLIC DOMAIN: Han Boetes <han@boetes.org>
 * $Id: empty_message.c,v 1.7 2005/04/30 14:15:31 han Exp $
 */

#include <stdio.h>
#define MAXLINES 255

int main(void)
{
	int ch;
	int counter = 0;
	while ((ch = getchar()) != EOF)
	{
		/* If we find a newline */
		if (ch != '\n')
			continue;

		/* get the next character */
		ch = getchar();
		switch (ch)
		{
		case EOF:
			return 0;
		case '\n':
			/* Ow boy, a message with multiple empty lines,
			 * now what? */
			while ((ch = getchar()) == '\n')
				if (counter++ >= MAXLINES)
					return 1;
			/* now if the current char is EOF we have an
			 * empty message */
			if (ch == EOF)
				return 1;
			else
				/* in other cases we don't have an emtpy
				 * message */
				return 0;
		}
	}
	return 1;
}
