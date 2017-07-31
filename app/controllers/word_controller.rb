require 'open-uri'
require 'json'

class WordController < ApplicationController

  def generate_grid(grid_size)
    alphabet = ('A'..'Z').to_a + ('A'..'Z').to_a
    alphabet.sample(grid_size)
  end

  def score_time(start_time, end_time)
    end_time.sec - start_time.sec
  end

  def parse_attempt_translation(attempt)
    parameters = '?source=en&target=fr&key=13f3a994-55d1-4e46-aff8-b2045f870f5a&input='
    url = 'https://api-platform.systran.net/translation/text/translate' + parameters + attempt
    url_serialized = open(url).read
    result_hash = JSON.parse(url_serialized)
    result = result_hash['outputs'][0]['output']
    return result if attempt != result
  end

  def scoring(attempt, grid, start_time, end_time)
    score = 0
    character_number = parse_character_number(attempt).to_i
    character_number.times { score += 10 }
    score_time = end_time.sec - start_time.sec
    score_time.times { score -= 1 }
    score = 0 if attempt_english?(attempt) == false
    score = 0 if attempt_in_grid?(attempt, grid) == false
    score = 0 if enough_letters?(attempt, grid) == false
    score
  end

  def parse_character_number(attempt)
    parameters = '?source=en&target=fr&key=13f3a994-55d1-4e46-aff8-b2045f870f5a&input='
    url = 'https://api-platform.systran.net/translation/text/translate' + parameters + attempt
    url_serialized = open(url).read
    result_hash = JSON.parse(url_serialized)
    result_hash['outputs'][0]['stats']['nb_characters']
  end

  def attempt_english?(attempt)
    !parse_attempt_translation(attempt).nil? ? true : false
  end

  def attempt_in_grid?(attempt, grid)
    attempt_array = attempt.downcase.split("")
    counter = 0
    attempt_array.each { |letter| counter += 1 if grid.include?(letter.upcase) }
    counter == parse_character_number(attempt).to_i ? true : false
  end

  def enough_letters?(attempt, grid)
    attempt_hash = Hash.new(0)
    grid_hash = Hash.new(0)
    attempt.downcase.split("").each { |letter| attempt_hash[letter] += 1 }
    grid.split("").each { |letter| grid_hash[letter.downcase] += 1 }
    test_array = []
    attempt_hash.each { |key, value| value <= grid_hash[key] ? test_array << true : test_array << false }
    test_array.include?(false) ? false : true
  end

  def message_return(attempt, grid)
    return "not in the grid" if enough_letters?(attempt, grid) == false
    return "well done" if attempt_english?(attempt) == true && attempt_in_grid?(attempt, grid) == true
    return "not an english word" if attempt_english?(attempt) == false
    return "not in the grid" if attempt_in_grid?(attempt, grid) == false
  end
  #-----------------------------------------------------------

  def game
    $grid = generate_grid(9).join(" ")
    $start_time = Time.now
  end

  def score
    @grid = $grid
    @start_time = $start_time
    @end_time = Time.now
    @attempt = params[:attempt]
    @result = Hash.new(0)
    @result[:time] = score_time(@start_time, @end_time)
    @result[:translation] = parse_attempt_translation(@attempt)
    @result[:score] = scoring(@attempt, @grid, @start_time, @end_time)
    @result[:message] = message_return(@attempt, @grid)
  end
end
