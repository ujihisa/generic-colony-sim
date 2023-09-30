# frozen_string_literal: true

class Game
  def initialize
    @oxygen_pressure = 1.0
    @co2_pressure = 0.0
    @stored_food = 5.0
    @temperature = 20.0
    @day = 0
    @time = 0

    @dig_raw_mineral_distance = 0
    @storage = {
      raw_mineral: 0,
    }
  end

  def ticks(time_diff)
    @time += time_diff

    @oxygen_pressure -= 0.1 * time_diff
    @co2_pressure += 0.1 * time_diff

    if 8 < @time
      @oxygen_pressure -= 0.1 * 16
      @co2_pressure += 0.1 * time_diff
      @food -= 1.0

      @time -= 8
      @day += 1
    end
  end

  def dig_raw_mineral
    @dig_raw_mineral_distance += 1
    @storage[:raw_mineral] += 3

    ticks(@dig_raw_mineral_distance * 0.1)
  end
end

g = Game.new

pp g
g.dig_raw_mineral
pp g
