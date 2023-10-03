# frozen_string_literal: true

require './lib/action'
require './lib/building'

class Game
  attr_accessor(
    :oxygen_pressure,
    :co2_pressure,
    :stored_food,
    :temperature,
    :day,
    :time,
    :dig_raw_mineral_distance,
    :harvest_wild_plant_distance,
    :storage,
    :max_storage,
    :building,
    :farm_size,
    :power,
    :power_capacity,
    :housing_level,
  )
  def initialize(*args, **kwargs)
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
    @building = {}
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
    可能な行動:     #{Action.available_action_targets(self).map { _2 == :default ? t(_1) : "#{t(_1)}/#{t(_2)}" }.join(', ')}
    EOS
  end

  def t(s)
    {
      Action::DigRawMineral => '無機物原石鉱脈を採掘',
      Action::HarvestWildPlant => '野生植物を採取',
      Action::RunManualOxygenDiffuser => '手動酸素散布装置を稼働',
      Action::ExpandFarm => '畑を拡張',
      Action::ImproveHousing => '居住区を改善',
      Action::RunManualGenerator => '人力発電機を稼働',
      Action::BuildBuilding => '施設を建設',
      fertilizer: '肥料',
      raw_mineral: '無機物原石',
      algae: '緑藻',
    }.fetch(s, s)
  end

  def run_action!(action_mod)
    puts "=> Run #{t(action_mod)} (#{action_mod.tick(self)}時間 #{action_mod.cost(self)[:storage]})"
    if !Action.available_actions(self).include?(action_mod.class)
      raise "The action #{action_mod.class.name} is not available. (available_actions: #{Action.available_actions(self)})"
    end

    action_mod.do!(self)
    cost = action_mod.cost(self)
    cost.fetch(:storage, {}).each do |k, amount|
      put_storage!(k, -amount)
    end
    ticks_needed = action_mod.tick(self)

    ticks!(ticks_needed)
  end

  # Basically everything below is private, but I keep them public while prototyping

  def ticks!(time_diff)
    @time += time_diff

    @oxygen_pressure -= 0.04 * time_diff
    @co2_pressure += 0.04 * time_diff
    if @power_capacity < @power
      @power = @power_capacity
    end

    if 8 < @time
      # rest time

      # farm
      vol = [@farm_size, @storage[:fertilizer]].min
      put_storage!(:fertilizer, -vol)
      @stored_food += vol * 0.1

      @oxygen_pressure -= 0.04 * 16
      @co2_pressure += 0.04 * 16
      @stored_food -= 1.0

      @time -= 8
      @day += 1
    end
  end

  # must call after any actions
  def gameover?
    case
    when @oxygen_pressure < 0
      p '[GAMEOVER] No oxygen!'
      true
    when @stored_food < 0
      p '[GAMEOVER] No food!'
      true
    when @temperature < 10
      p '[GAMEOVER] Too cold!'
      true
    when @temperature > 40
      p '[GAMEOVER] Too hot!'
      true
    end
  end

  def put_storage!(key, amount)
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

  ats = Action.available_action_targets(g)
  if ats.include?([Action::RunManualOxygenDiffuser, :default])
    (a, t) = [Action::RunManualOxygenDiffuser, :default]
  else
    (a, t) = ats.sample
  end
  g.run_action!(a.new(t))
end

puts g.to_japanese
pp g
