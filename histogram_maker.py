import matplotlib.pyplot as plt

def create_histogram(filename, width=8, height=6):
    """Creates a histogram of the 10 most frequent words in a given file.

    Args:
        filename: The name of the file containing the words and their frequencies.
    """
    plt.figure(figsize=(width, height))
    # Read the words and frequencies from the file
    with open(filename, 'r') as f:
        data = f.read().strip().split()
        words = data[::2]
        frequencies = map(int, data[1::2])

    # Create a dictionary to store word-frequency pairs
    word_freq_dict = dict(zip(words, frequencies))

    # Sort the dictionary by frequency in descending order
    sorted_word_freq = sorted(word_freq_dict.items(), key=lambda x: x[1], reverse=True)

    # Take the top 10 most frequent words
    top_10_words = sorted_word_freq[:10]

    # Sort the top 10 words alphabetically
    top_10_words = sorted(top_10_words, key=lambda x: x[0])

    # Extract words and frequencies for plotting
    x_labels = [word for word, freq in top_10_words]
    y_values = [freq for word, freq in top_10_words]

    # Create the histogram
    plt.bar(x_labels, y_values, color='blue')
    plt.xlabel('Words')
    plt.ylabel('Frequency')
    plt.title('Top 10 Most Frequent Words')
    plt.xticks(rotation=45)
    
    plt.show()

# Example usage
filename = 'frequencies.txt'  # Replace with your file name
create_histogram(filename, width=8, height=8)