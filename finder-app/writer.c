#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    // Check if the correct number of arguments are provided
    openlog(NULL, 0, LOG_USER);
    if (argc != 3) {
        syslog(LOG_ERR, "Error: Two arguments required - <path to file> and <string to write>\n");
        return 1;
    }

    // Assign arguments to variables
    const char *writefile = argv[1];
    const char *writestr = argv[2];

    // Open the file for writing (this will overwrite the file if it exists)
    FILE *file = fopen(writefile, "w");
    
    // Check if the file could be opened/created
    if (file == NULL) {
        syslog(LOG_ERR, "Error: Could not create or open the file\n");
        return 1;
    }

    // Write the string to the file
    syslog(LOG_DEBUG, "Writing %s to %s \n", writestr, writefile);
    if (fprintf(file, "%s", writestr) < 0) {
        syslog(LOG_ERR, "Error: Could not write to the file\n");
        fclose(file);
        return 1;
    }

    // Close the file
    fclose(file);

    return 0;
}

