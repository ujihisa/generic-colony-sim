# frozen_string_literal: true

require './lib/action'

class Game
  attr_accessor :storage, :housing_level, :dig_raw_mineral_distance

  def initialize
    @oxygen_pressure = 1.0
    @co2_pressure = 0.0
    @stored_food = 5.0
    @temperature = 20.0
    @day = 0
    @time = 0

    @dig_raw_mineral_distance = 0
    @harvest_wild_plant_distance = 0
    @storage = {
      raw_mineral: 0,
      fertilizer: 2,
      algae: 3,
    }
    @max_storage = 100
    @farm_size = 0
    @power = 0
    @power_capacity = 0
    @housing_level = 1
  end

  def to_japanese
    <<~EOS
    --------------------------------------
    現在日時:       #{@day}日#{'%.2f' % @time}時間経過
    酸素気圧:       #{'%.2f' % @oxygen_pressure}
    二酸化炭素気圧: #{'%.2f' % @co2_pressure}
    貯蔵食料:       #{'%.1f' % @stored_food}
    気温:           #{@temperature}C
    貯蔵庫:         #{@storage.map { "#{t(_1)}#{_2}kg" }.join(', ')} (残り容量 #{@max_storage - @storage.values.sum}kg)
    畑のサイズ:     #{@farm_size}
    電力:           #{@power}kJ / #{@power_capacity}kJ
    居住区レベル:   #{'☆' * @housing_level}
    可能な行動:     #{Action.available_actions(self).map { t(_1) }.join(', ')}
    EOS
  end

  def t(s)
    {
      dig_raw_mineral!: '無機物原石鉱脈を採掘',
      harvest_wild_plant!: '野生植物を採取',
      run_manual_oxygen_diffuser!: '手動酸素散布装置を稼働',
      expand_farm!: '畑を拡張',
      improve_housing!: '居住区を改善',
      run_manual_generator!: '人力発電機を稼働',
      fertilizer: '肥料',
      raw_mineral: '無機物原石',
      algae: '緑藻',
    }.fetch(s, s)
  end

  def run_action!(action_name)
    if !Action.available_actions(self).include?(action_name)
      raise "The action #{action_name} is not available. (available_actions: #{Action.available_actions(self)})"
    end

    ticks_needed =
      case action_name
      when :dig_raw_mineral!
        Action::DigRawMineral.do!(self)
        Action::DigRawMineral.cost(self).each do |k, amount|
          put_storage!(k, -amount)
        end
        Action::DigRawMineral.tick(self)
      when :harvest_wild_plant!
        harvest_wild_plant!
      when :run_manual_oxygen_diffuser!
        run_manual_oxygen_diffuser!
      when :expand_farm!
        expand_farm!
      when :run_manual_generator!
        run_manual_generator!
      when :improve_housing!
        improve_housing!
      else
        raise 'Must not happen'
      end
    ticks!(ticks_needed)
  end

  # Basically everything below is private, but I keep them public while prototyping

  def ticks!(time_diff)
    @time += time_diff

    @oxygen_pressure -= 0.1 * time_diff
    @co2_pressure += 0.1 * time_diff
    if @power_capacity < @power
      @power = @power_capacity
    end

    if 8 < @time
      # rest time

      # farm
      vol = [@farm_size, @storage[:fertilizer]].min
      put_storage!(:fertilizer, -vol)
      @stored_food += vol * 0.1

      @oxygen_pressure -= 0.1 * 16
      @co2_pressure += 0.1 * 16
      @stored_food -= 1.0

      @time -= 8
      @day += 1
    end
  end

  # must call after any actions
  def gameover?
    case
    when @oxygen_pressure < 0
      p 'No oxygen!'
      true
    when @stored_food < 0
      p 'No food!'
      true
    when @temperature < 10
      p 'Too cold!'
      true
    when @temperature > 40
      p 'Too hot'
      true
    end
  end

  def harvest_wild_plant!
    @harvest_wild_plant_distance += 1
    @stored_food += 3
    if 10 < @stored_food
      p("Too much stored food. Discarded #{@stored_food - 10}")
      @stored_food = 10
    end

    1.0 + @harvest_wild_plant_distance**2
  end

  # requires algae 1
  def run_manual_oxygen_diffuser!
    put_storage!(:algae, -1)
    @oxygen_pressure += 1.0

    2.0
  end

  def run_manual_generator!
    @power += 400
    1.0
  end

  def expand_farm!
    @farm_size += 1

    2.0
  end

  HOUSING_COST = {
    1 => {
      raw_mineral: 6,
    },
    2 => {
      raw_mineral: 12,
    },
    3 => {
      raw_mineral: 24,
    },
    4 => {
      raw_mineral: 48,
    },
  }.freeze

  def improve_housing!
    costs_hash = HOUSING_COST[@housing_level]
    costs_hash.each do |key, amount|
      @storage[key] -= amount
    end

    @housing_level += 1

    3.0
  end

  private def put_storage!(key, amount)
    existing_amount = @storage.values.sum

    if existing_amount + amount <= @max_storage
      @storage[key] += amount
    else
      discarded = amount - (@max_storage - existing_amount)
      p("Out of storage. #{discarded} (out of #{amount}) of #{key} is discarded.")
      @storage[key] += amount - discarded
    end
  end
end

g = Game.new

pp g
until g.gameover?
  puts g.to_japanese

  aa = Action.available_actions(g)
  if aa.include?(:run_manual_oxygen_diffuser!)
    g.run_action!(:run_manual_oxygen_diffuser!)
  else
    g.run_action!(aa.sample)
  end

end
puts g.to_japanese
pp g
