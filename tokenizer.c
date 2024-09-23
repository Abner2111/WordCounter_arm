#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

// Function to replace accented characters with their regular versions
char normalize_char(char ch) {
    switch (ch) {
        
        case 'Á': case 'À': case 'Ã': case 'Â': case 'Ä':
            return 'a';
        case 'é': case 'è': case 'ê': case 'ë':
            return 'e';
        case 'É': case 'È': case 'Ê': case 'Ë':
            return 'e';
        case 'í': case 'ì': case 'î': case 'ï':
            return 'i';
        case 'Í': case 'Ì': case 'Î': case 'Ï':
            return 'i';
        case 'ó': case 'ò': case 'õ': case 'ô': case 'ö':
            return 'o';
        case 'Ó': case 'Ò': case 'Õ': case 'Ô': case 'Ö':
            return 'o';
        case 'ú': case 'ù': case 'û': case 'ü':
            return 'u';
        case 'Ú': case 'Ù': case 'Û': case 'Ü':
            return 'u';
        case 'ñ':
            return 'n';
        case 'Ñ':
            return 'n';
        case 'ç':
            return 'c';
        case 'Ç':
            return 'c';
        default:
            return ch;
    }
}

void tokenize_file(const char *input_filename, const char *output_filename) {
    FILE *input_file = fopen(input_filename, "r");
    if (input_file == NULL) {
        perror("Error opening input file");
        return;
    }

    FILE *output_file = fopen(output_filename, "w");
    if (output_file == NULL) {
        perror("Error opening output file");
        fclose(input_file);
        return;
    }

    char ch;
    int in_word = 0;

    // Read the file character by character
    while ((ch = fgetc(input_file)) != EOF) {
        ch = tolower(ch);               // Convert to lowercase
        //ch = normalize_char(ch);        // Replace accented characters
    
        if (isalnum(ch)|| (unsigned char)ch >= 128) {
            // If it's a part of a word (alphanumeric), write it to the output file
            fputc(ch, output_file);
            in_word = 1;
        } else {
            // If we encounter a non-word character (space, punctuation, etc.)
            if (ch == '-'){
                continue;
            }
            if (in_word) {
                // Write a space only if it marks the end of a word
                fputc(' ', output_file);
                in_word = 0;
            }
            
        }
    }

    // Close both files
    fclose(input_file);
    fclose(output_file);
}

int main(int argc, char *argv[]) {
    // Check if the filename is provided as an argument
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_filename>\n", argv[0]);
        return 1;
    }

    // Get the input file from the command-line argument
    const char *input_file = argv[1];
    const char *output_file = "tokenized_text.txt";  // Output file

    tokenize_file(input_file, output_file);

    printf("Tokenized text has been written to %s\n", output_file);
    return 0;
}
