/* Count to three in a spectacular way */
#include <stdio.h>
#include <unistd.h>

int main(void)
{
	int             i;
	for (i = 30; i >= 0; i--) {
		usleep(100000);
		if (i % 10 == 0) {
			printf("%i", i / 10);
		} else {
			printf(".");
		}
                fflush(NULL);
	}
	return 0;
}
