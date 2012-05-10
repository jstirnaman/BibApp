#configure the stop words in a reasonable way for testing
require 'set'
require 'stop_word_processor'
StopWordProcessor.instance.stopword_set = ['a', 'an', 'the'].to_set