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
    @harvest_wild_plant_distance = 1
    @storage = {
      raw_mineral: 0,
      fertilizer: 2,
      algae: 3,
    }
    @max_storage = 100
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
    可能な行動:     #{available_actions.map { t(_1) }.join(', ')}
    EOS
  end

  def t(s)
    {
      dig_raw_mineral!: '無機物原石鉱脈を採掘する',
      harvest_wild_plant!: '野生植物を採取する',
      run_manual_oxygen_diffuser!: '手動酸素散布装置を稼働する',
      fertilizer: '肥料',
      raw_mineral: '無機物原石',
      algae: '緑藻',
    }.fetch(s, s)
  end

  def available_actions
    available = [
      :dig_raw_mineral!,
      :harvest_wild_plant!,
    ]
    if 1 <= @storage[:algae]
      available += [:run_manual_oxygen_diffuser!]
    end
    available
  end

  def run_action!(action_name)
    if !available_actions.include?(action_name)
      raise "The action #{action_name} is not available. (available_actions: #{available_actions})"
    end

    ticks_needed =
      case action_name
      when :dig_raw_mineral!
        dig_raw_mineral!
      when :harvest_wild_plant!
        harvest_wild_plant!
      when :run_manual_oxygen_diffuser!
        run_manual_oxygen_diffuser!
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

    if 8 < @time
      @oxygen_pressure -= 0.1 * 16
      @co2_pressure += 0.1 * time_diff
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

  # action
  def dig_raw_mineral!
    @dig_raw_mineral_distance += 1
    put_storage!(:raw_mineral, 3)
    put_storage!(:fertilizer, 1)
    put_storage!(:algae, 1)

    @dig_raw_mineral_distance * 0.1
  end

  # action
  def harvest_wild_plant!
    @harvest_wild_plant_distance *= 2
    @stored_food += 5
    if 10 < @stored_food
      p("Too much stored food. Discarded #{@stored_food - 10}")
      @stored_food = 10
    end

    @harvest_wild_plant_distance * 0.1
  end

  # action
  # requires algae 1
  def run_manual_oxygen_diffuser!
    put_storage!(:algae, -1)
    @oxygen_pressure += 1.0

    2.0
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
  action = g.available_actions.sample
  g.run_action!(action)
  puts g.to_japanese
end
pp g
