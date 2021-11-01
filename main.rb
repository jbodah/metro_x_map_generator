require 'stringio'
require 'benchmark'

METRO_CITY = [
  {
    name: :red,
    num_boxes: 2,
    high_value: 2,
    low_value: 1,
    path: [1, 2, 3, 4, 5, 6, 15, 16, 17, 18, 19],
  },
  {
    name: :orange,
    num_boxes: 2,
    high_value: 4,
    low_value: 2,
    path: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
  },
  {
    name: :pink,
    num_boxes: 3,
    high_value: 7,
    low_value: 5,
    path: [20, 21, 22, 8, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32],
  },
  {
    name: :green,
    num_boxes: 3,
    high_value: 5,
    low_value: 3,
    path: [33, 34, 35, 36, 17, 37, 10, 38, 39, 40, 24, 41, 42, 43, 44, 6],
  },
  {
    name: :yellow,
    num_boxes: 3,
    high_value: 4,
    low_value: 3,
    path: [45, 18, 46, 47, 38, 39, 11, 24, 41, 48, 49, 50, 51, 52],
  },
  {
    name: :purple,
    num_boxes: 2,
    high_value: 4,
    low_value: 2,
    path: [19, 46, 68, 10, 23, 69, 24, 70, 71, 72, 73],
  },
  {
    name: :blue,
    num_boxes: 2,
    high_value: 5,
    low_value: 3,
    path: [19, 46, 68, 10, 38, 74, 40, 25, 70, 59, 60, 75, 76],
  },
  {
    name: :grey,
    num_boxes: 3,
    high_value: 6,
    low_value: 4,
    path: [53, 54, 55, 39, 11, 40, 56, 57, 26, 58, 59, 60, 61, 51],
  },
  {
    name: :dark_green,
    num_boxes: 3,
    high_value: 4,
    low_value: 2,
    path: [62, 63, 64, 38, 10, 37, 9, 8, 43, 65, 66, 67],
  }
]

TUBE_TOWN = [
  {
    name: :red,
    num_boxes: 2,
    high_value: 4,
    low_value: 2,
    path: [1, 2, 3, 4, 5, 6, 7, 8, 9],
  },
  {
    name: :orange,
    num_boxes: 4,
    high_value: 7,
    low_value: 5,
    path: [10, 3, 11, 12, 13, 14, 15, 16, 78, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26],
  },
  {
    name: :green,
    num_boxes: 2,
    high_value: 4,
    low_value: 2,
    path: [14, 27, 16, 28, 29, 30, 31, 32, 33, 34],
  },
  {
    name: :pink,
    num_boxes: 3,
    high_value: 6,
    low_value: 4,
    path: [35, 36, 37, 38, 39, 40, 41, 42, 33, 21, 43, 44, 45, 46],
  },
  {
    name: :yellow,
    num_boxes: 2,
    high_value: 3,
    low_value: 2,
    path: [47, 48, 39, 40, 41, 42, 49, 50, 51],
  },
  {
    name: :purple,
    num_boxes: 3,
    high_value: 4,
    low_value: 2,
    path: [52, 53, 54, 55, 41, 31, 19, 56, 9, 57, 58],
  },
  {
    name: :blue,
    num_boxes: 2,
    high_value: 5,
    low_value: 3,
    path: [59, 60, 61, 53, 62, 39, 29, 63, 17, 64, 8, 65, 66],
  },
  {
    name: :grey,
    num_boxes: 2,
    high_value: 2,
    low_value: 1,
    path: [59, 67, 68, 69, 70, 51],
  },
  {
    name: :dark_green,
    num_boxes: 3,
    high_value: 4,
    low_value: 2,
    path: [71, 54, 72, 40, 30, 73, 18, 74, 64, 75, 6, 76, 77],
  },
]

OZAKU_CARDS = {
  transfer: 3,
  free: 1,
  skip2: 2,
  skip3: 1,
  n2: 2,
  n3: 4,
  n4: 5,
  n5: 2,
  reshuffle6: 1,
}

GAMEWRIGHT_CARDS = {
  transfer: 2,
  free: 1,
  skip2: 2,
  skip3: 1,
  n3: 3,
  n4: 4,
  n5: 2,
  reshuffle6: 1,
}

class Station
  attr_reader :name, :path, :high_value, :low_value, :boxes, :num_boxes

  def initialize(name, path, high_value, low_value, num_boxes)
    @name = name
    @path = path
    @high_value = high_value
    @low_value = low_value
    @num_boxes = num_boxes

    @boxes = []
  end

  def full?
    @boxes.size == @num_boxes
  end

  def mark_box(number)
    @boxes << number
  end

  def num_remaining_boxes
    @num_boxes - @boxes.size
  end
end

class Transfer
  attr_reader :node

  def initialize(node, hit_count)
    @node = node
    @hit_count = hit_count
    @scored = false
  end

  def value
    2 * @hit_count
  end

  def scored?
    @scored
  end

  def mark_scored
    raise 'already scored' if @scored
    @scored = true
  end
end

class Node < Struct.new(:node_id, :is_marked, :transfer)
  def marked?; is_marked; end
  def not_marked?; !marked?; end
  def mark!; self.is_marked = true; end
end

class Board
  attr_reader :stations, :transfers, :nodes

  def initialize(map_spec)
    @map_spec = map_spec

    @stations = build_stations(map_spec)
    @nodes = build_nodes(map_spec)
    @transfers = build_transfers(map_spec, nodes)
  end

  def build_stations(map_spec)
    map_spec.map do |route|
      Station.new(route[:name], route[:path], route[:high_value], route[:low_value], route[:num_boxes])
    end
  end

  def build_transfers(map_spec, nodes)
    node_hits = map_spec.flat_map do |route|
      route[:path]
    end

    node_to_hit_count = node_hits.group_by { |node| node }.transform_values { |nodes| nodes.size }

    node_to_hit_count.select! { |_, hit_count| hit_count > 1 }

    node_to_hit_count.map do |node, hit_count|
      nodes[node].transfer = Transfer.new(node, hit_count)
    end
  end

  def build_nodes(map_spec)
    nodes = map_spec.flat_map { |route| route[:path] }.uniq
    @nodes = {}
    nodes.each { |n| @nodes[n] = Node.new(n, false, nil) }
    @nodes
  end

  def count_station_path_transfers(station)
    get_node_states(*station.path).count { |node| !node.transfer.nil? }
  end

  def score
    completed_station_score + transfer_score + empty_node_score
  end

  def score_breakdown
    {
      total: score,
      completed_station_score: completed_station_score,
      transfer_score: transfer_score,
      empty_node_score: empty_node_score,
      num_empty_nodes: num_empty_nodes,
    }
  end

  def completed_station_score
    @stations.select { |s| station_path_completed?(s) }.map(&:high_value).sum
  end

  def transfer_score
    @transfers.select(&:scored?).map(&:value).sum
  end

  def num_empty_nodes
    @nodes.values.reject(&:marked?).count
  end

  def num_remaining_path_nodes
    available_stations.flat_map(&:path).uniq.count { |node| !node_marked?(node) }
  end

  def get_node_states(*nodes)
    @nodes.fetch_values(*nodes)
  end

  def empty_node_score
    case num_empty_nodes
    when (0..4) then 0
    when 5 then -1
    when 6 then -2
    when 7 then -3
    when 8, 9 then -4
    when 10, 11 then -5
    when 12, 13 then -6
    when 14, 15 then -7
    when 16, 17 then -8
    when 18, 19 then -9
    when (20..) then -10
    else
      raise 'something terrible happened'
    end
  end

  def available_stations
    available_stations = @stations.reject { |s| s.full? }
    raise 'all stations full' if available_stations.size == 0
    available_stations
  end

  def station_path_completed?(station)
    station.path.all? { |node| node_marked?(node) }
  end

  def available_transfers
    @transfers.reject { |t| node_marked?(t.node) }
  end

  def stations_full?
    @stations.all?(&:full?)
  end

  def node_marked?(node_id)
    @nodes.fetch(node_id).marked?
  end

  def nodes_marked?(nodes)
    nodes.all? { |n| node_marked?(n) }
  end

  def mark_node(node_id)
    raise 'already marked' if node_marked?(node_id)
    @nodes.fetch(node_id).mark!
  end

  def mark_transfer(transfer, station)
    raise 'already marked' if node_marked?(transfer.node)
    mark_node(transfer.node)
    transfer.mark_scored
    station.mark_box(0)
  end

  def mark_up_to_n_nodes_on_route(n_desired, station, free: false, skip: false)
    n = n_desired

    station.mark_box(n) unless free

    return 0 if station_path_completed?(station)

    node_queue = station.path.dup

    start_node = nil
    loop do
      start_node = node_queue.shift
      break if !node_marked?(start_node)
    end

    raise 'no start node' if start_node.nil?

    mark_node(start_node)
    n -= 1
    until n == 0 || node_queue.empty?
      next_node = node_queue.shift
      # TODO: @jbodah 2020-07-11: maybe add a hopper?
      if skip == false
        if node_marked?(next_node)
          break
        else
          mark_node(next_node)
          n -= 1
        end
      else
        if node_marked?(next_node)
          # proceed & don't reduce available x's
        else
          mark_node(next_node)
          n -= 1
        end
      end
    end

    n_desired - n
  end
end

class Debug
  class << self
    def dump_station_path(board, station)
      puts debug_station_path.inspect
    end

    def dump_game(game)
      dump_board(game.board)
      dump_deck(game.deck)
    end

    def dump_board(board)
      puts "# Stations"
      board.stations.each do |station|
        puts <<~DEBUG
        ## #{station.name}
        \tboxes: #{debug_station_boxes(station).inspect}
        \tpath: #{debug_station_path(board, station).inspect}
        DEBUG
      end
    end

    def visualize_board(board)
      io = StringIO.new
      board.stations.each do |station|
        queue = station.path.dup

        acc = []
        queue.each do |node|
          if board.node_marked?(node)
            acc << "(#{node})"
          else
            acc << node
          end
        end
        prefix = "#{station.name.inspect} #{debug_station_boxes(station).inspect}".ljust(30)
        io.puts "- #{prefix} => #{acc.join('-')}"
      end
      io.string
    end

    def dump_deck(deck)
      puts "# Deck"
      puts "- deck: #{deck.deck.inspect}"
      puts "- discard: #{deck.discard.inspect}"
    end

    def debug_station_path(board, station)
      station.path.map { |n| [n, board.node_marked?(n)] }
    end

    def debug_station_boxes(station)
      (0...station.num_boxes).map { |idx| station.boxes[idx] }
    end
  end
end

class Card
  class << self
    def build(spec)
      case spec
      when :transfer
        TransferCard.new
      when :free
        FreeCard.new
      when :skip2
        SkipCard.new(2)
      when :skip3
        SkipCard.new(3)
      when :n2
        NumberCard.new(2)
      when :n3
        NumberCard.new(3)
      when :n4
        NumberCard.new(4)
      when :n5
        NumberCard.new(5)
      when :reshuffle6
        ReshuffleCard.new(6)
      else
        raise spec.inspect
      end
    end
  end
end

class TransferCard
  def reshuffle?
    false
  end
end

class FreeCard
  def reshuffle?
    false
  end

  def number
    1
  end
end

class SkipCard
  attr_reader :number

  def initialize(number)
    @number = number
  end

  def reshuffle?
    false
  end
end

class NumberCard
  attr_reader :number

  def initialize(number)
    @number = number
  end

  def reshuffle?
    false
  end
end

class ReshuffleCard
  attr_reader :number

  def initialize(number)
    @number = number
  end

  def reshuffle?
    true
  end
end

class Deck
  attr_reader :cards, :discard, :deck

  def initialize(cards)
    @cards = cards
    reshuffle
  end

  def discard
    @discard
  end

  def reshuffle
    if $deterministic
      @deck = @cards
    else
      @deck = @cards.shuffle
    end
    @discard = []
  end

  def draw
    raise "horribly wrong" if @deck.empty?
    drawn, *rest = @deck
    @deck = rest
    yield drawn
    if drawn.reshuffle?
      reshuffle
    else
      @discard << drawn
    end
  end
end

class History
  attr_accessor :draw_history

  def initialize(io = $stdout)
    @io = io
    @draw_history = []
  end

  def record_event(msg, importance: :low)
    if importance == :high
      @io.puts "### #{msg}"
    else
      @io.puts "#{msg}"
    end
  end

  def proxy(obj)
    History::Proxy.new(self, obj)
  end

  class Proxy
    def initialize(history, delegate)
      @history = history
      @delegate = delegate
    end

    def draw
      @delegate.draw do |card|
        puts "Drew #{card.inspect}"
        if $record_draw_history
          if @history.draw_history.size > 0
            puts "Draw History:"
            @history.draw_history.each do |prev_draw|
              puts "- #{prev_draw.inspect}"
            end
          end
        end
        yield card
        @history.draw_history << card
      end
    end

    def mark_transfer(t, s)
      @delegate.mark_transfer(t, s).tap do
        puts "Action: transfer @ #{t.node}; boxed station #{s.name.inspect}: #{[t, s].inspect}"
      end
    end

    def mark_up_to_n_nodes_on_route(n, s, **kwargs)
      @delegate.mark_up_to_n_nodes_on_route(n, s, **kwargs).tap do |rv|
        puts "Action: #{s.name.inspect} #{rv}/#{n} (#{kwargs.inspect}): #{[n, s, kwargs].inspect}"
      end
    end

    def method_missing(sym, *args, &blk)
      @delegate.public_send(sym, *args, &blk)
    end

    private

    def puts(msg)
      @history.record_event(msg)
    end
  end
end

class Game
  attr_reader :board, :deck

  def initialize(map_spec, deck, player)
    @board = Board.new(map_spec)
    @deck = deck
    @player = player
    if $record_history
      fd = File.open('audit.log', 'w')
      fd.sync = true
      @history = History.new(fd)
      @turn = 0
    end
  end

  def play(score_breakdown: false)
    take_turn until game_over?
    calculate_score(breakdown: score_breakdown)
  rescue => e
    Debug.dump_game(self)
    raise e
  end

  def calculate_score(breakdown: false)
    return calculate_score_breakdown if breakdown
    @board.score
  end

  def calculate_score_breakdown
    @board.score_breakdown
  end

  def game_over?
    @board.stations_full?
  end

  def take_turn
    if $record_history
      @turn += 1
      @history.record_event("Turn #{@turn}", importance: :high)
      @history.record_event("Stations Remaining: #{@board.available_stations.size}")
      @history.record_event("Station Boxes Remaining: #{@board.available_stations.map(&:num_remaining_boxes).sum}")
      @history.record_event("Path Nodes Remaining: #{@board.num_remaining_path_nodes}")
      @history.record_event("Transfers Remaining: #{@board.available_transfers.size}")
      before = Debug.visualize_board(@board)
      @player.take_turn(@history.proxy(@board), @history.proxy(@deck))
      @history.record_event("Before:\n" + before)
      @history.record_event("After:\n" + Debug.visualize_board(@board))
      @history.record_event("Current score: #{calculate_score_breakdown.inspect}")
    else
      @player.take_turn(@board, @deck)
    end
  end
end

class Player
  attr_accessor :statistics

  def initialize
    @statistics = Hash.new { |h, k| h[k] = 0 }
  end

  def take_turn(board, deck)
    @__board = board
    @__cache = {}

    deck.draw do |card|
      case card
      when NumberCard
        station = handle_number(board, deck, card)
        board.mark_up_to_n_nodes_on_route(card.number, station)
      when TransferCard
        node, station = handle_transfer(board, deck, card)
        node ? board.mark_transfer(node, station) : station.mark_box(0)
      when FreeCard
        node = handle_free(board, deck, card)
        # NOTE: @jbodah 2020-07-12: we can run out of placesjjjj
        board.mark_node(node) unless node.nil?
      when SkipCard
        station = handle_skip(board, deck, card)
        board.mark_up_to_n_nodes_on_route(card.number, station, skip: true)
      when ReshuffleCard
        station = handle_reshuffle(board, deck, card)
        board.mark_up_to_n_nodes_on_route(card.number, station)
      else
        raise card.inspect
      end
    end
  end

  def handle_skip(*a); handle_number(*a); end
  def handle_reshuffle(*a); handle_number(*a); end

  def available_transfers
    @__board.available_transfers
  end

  def available_stations
    @__board.available_stations
  end

  def available_stations_with_incomplete_paths
    available_stations.select { |station| tail_path(station).size > 0 }
  end

  def any_station
    available_stations.sample
  end

  def any_station_with_an_incomplete_path
    available_stations_with_incomplete_paths.sample
  end

  def any_transfer
    available_transfers.sample
  end

  def tail_path(station)
    @__cache[:tail_path] ||= {}
    @__cache[:tail_path][station] ||= @__board.get_node_states(*station.path).drop_while(&:marked?)
  end

  def next_unmarked_link(station)
    tail_path(station).take_while(&:not_marked?)
  end

  def hole?(node)
    available_stations_with_incomplete_paths.any? do |station|
      tail_path = tail_path(station)
      _, idx = tail_path.each_with_index.find { |path_node, _| path_node.transfer == node }
      next false if idx.nil?
      next false if idx == 0 || idx == tail_path.size-1
      next true if tail_path[idx-1].marked? && tail_path[idx+1].marked?
      false
    end
  end
end

module HandleFree
  module None
    def handle_free(*a)
      nil
    end
  end

  module AnyIncompletePath
    def handle_free(board, deck, card)
      match = any_station_with_an_incomplete_path
      if match
        return tail_path(match).first.node_id
      end

      super
    end
  end

  module RandomHole
    def handle_free(board, deck, card)
      station_and_holes =
        available_stations_with_incomplete_paths.map do |station|
          hole =
            tail_path(station)
            .select(&:not_marked?)
            .find { |node| hole?(node) }
          [station, hole]
        end

      station_and_holes.reject! { |_, hole| hole.nil? }

      _, hole = station_and_holes.sample
      return hole if hole

      super
    end
  end

  module CompletePathNow
    def handle_free(board, deck, card)
      match =
        available_stations_with_incomplete_paths
        .select { |station| 1 == tail_path(station).select(&:not_marked?).size }
        .max_by(&:high_value)

      if match
        return tail_path(match).find(&:not_marked?).node_id
      end

      super
    end
  end
end

module HandleNumber
  module Random
    def handle_number(board, deck, card)
      any_station
    end
  end

  module CompletePathNow
    def handle_number(board, deck, card)
      match = find_highest_value_station_that_card_would_complete(card.number)
      return match if match

      super
    end

    def find_highest_value_station_that_card_would_complete(n)
        available_stations_with_incomplete_paths
          .select { |station| tail_path(station).none?(&:marked?) && n >= tail_path(station).size }
          .max_by(&:high_value)
    end
  end

  module AnyIncompletePath
    def handle_number(board, deck, card)
      match = any_station_with_an_incomplete_path
      return match if match

      super
    end
  end

  module PerfectFit
    def handle_number(board, deck, card)
      match =
        available_stations_with_incomplete_paths
        .find { |station| next_unmarked_link(station).size == card.number }
      return match if match

      super
    end
  end

  module MaximizePlacement
    def handle_number(board, deck, card)
      match =
        available_stations_with_incomplete_paths
        .sort_by { |station| -next_unmarked_link(station).length }
        .first
      return match if match

      super
    end
  end
end

module HandleTransfers
  module MaxByValue
    def handle_transfer(board, deck, card)
      if available_transfers.size == 0
        super
      else
        [available_transfers.max_by(&:value), any_station]
      end
    end
  end

  module Random
    def handle_transfer(board, deck, card)
      if available_transfers.size == 0
        [nil, any_station]
      else
        [any_transfer, any_station]
      end
    end
  end

  module CloseHoles
    def handle_transfer(board, deck, card)
      if available_transfers.size == 0
        super
      else
        match =
          available_transfers
          .select { |transfer| hole?(transfer) }
          .max_by { |transfer| transfer.value }
        return [match, any_station] if match

        super
      end
    end

    def edge?(node)
      available_stations_with_incomplete_paths.any? do |station|
        tail_path = tail_path(station)
        _, idx = tail_path.each_with_index.find { |path_node, _| path_node.transfer == node }
        next false if idx.nil?
        next true if idx == 0 || idx == tail_path.size-1
        next true if tail_path[idx-1].marked? || tail_path[idx+1].marked?
        false
      end
    end
  end
end

module HandleSkip
  module MaxSkippage
    def handle_skip(board, deck, card)
      match = available_stations_with_incomplete_paths.max_by { |station| skippage(station, card.number) }
      return match if match

      super
    end

    def skippage(station, skip_n)
      _, idx = tail_path(station).each_with_index.find { |node, idx| !node.marked? && (skip_n -= 1) < 0 }
      idx
    end
  end

  module CompletePathNow
    def handle_skip(board, deck, card)
      match = find_highest_value_station_that_card_would_complete_skip(card.number)
      return match if match

      super
    end

    def find_highest_value_station_that_card_would_complete_skip(n)
      available_stations_with_incomplete_paths
        .select { |station| n >= tail_path(station).reject(&:marked?).size }
        .max_by(&:high_value)
    end
  end

  module Random
    def handle_skip(board, deck, card)
      any_station
    end
  end

  module AnyIncompletePath
    def handle_skip(board, deck, card)
      match = any_station_with_an_incomplete_path
      return match if match

      super
    end
  end
end

module DefaultHandlers
  include HandleTransfers::Random
  include HandleTransfers::MaxByValue

  include HandleNumber::Random
  include HandleNumber::AnyIncompletePath
  include HandleNumber::MaximizePlacement
  include HandleNumber::PerfectFit
  include HandleNumber::CompletePathNow

  include HandleSkip::Random
  include HandleSkip::AnyIncompletePath
  include HandleSkip::MaxSkippage
  include HandleSkip::CompletePathNow

  include HandleFree::None
  include HandleFree::AnyIncompletePath
  include HandleFree::RandomHole
  include HandleFree::CompletePathNow
end

class FirstAvailableStationPlayer < Player
  def handle_transfer(board, deck, card)
    if available_transfers.size == 0
      [nil, available_stations.first]
    else
      [available_transfers.first, available_stations.first]
    end
  end

  def handle_number(board, deck, card)
    available_stations.first
  end
end

class RandomPlayer < Player
  include HandleTransfers::Random
  include HandleNumber::Random
end

class RandomButMaximizeTransfersPlayer < RandomPlayer
  include HandleTransfers::MaxByValue
end

class MaxFitPlayer < Player
  include DefaultHandlers
end

$deterministic = false
$breakdown = false
$iterations = 5000
$record_draw_history = false
$record_history = false
# $cards = OZAKU_CARDS
$cards = GAMEWRIGHT_CARDS
# $map = TUBE_TOWN
$map = METRO_CITY

Array.class_eval do
  def avg
    (sum.to_f / size).round(1)
  end

  def median
    sort[size / 2]
  end
end

def publish_stats(num_games)
  scores = nil
  bm = Benchmark.measure do
    scores = num_games.times.map do
      yield
    end
  end
  puts "[count] #{num_games}"
  puts "[bm-total] #{bm.real}"
  puts "[bm-avg] #{bm.real / num_games}"
  puts "[stats] #{{min: scores.min, max: scores.max, avg: scores.avg, median: scores.median}}"
end

def test_player(player_class, map = $map)
  puts "*** #{player_class} ***"
  player = player_class.new
  publish_stats($iterations) do
    cards = $cards.flat_map { |type, n| n.times.map { Card.build(type) }}
    deck = Deck.new(cards)

    game = Game.new(map, deck, player)

    game.play(score_breakdown: $breakdown)
  end
  puts player.statistics if player.statistics.any?
end

def analyze(map)
  board = Board.new(map)
  puts <<~EOF
  * Number of routes: #{board.stations.count}
  * Number of nodes: #{board.nodes.count}
  * Total route length: #{board.stations.map(&:path).map(&:size).sum}
  * Number of transfers: #{board.transfers.count}
  * Total route points: #{board.stations.map(&:high_value).sum}
  * Total transfer points: #{board.transfers.map(&:value).sum}

  * Min route length:  #{board.stations.map(&:path).map(&:size).min}
  * Max route length:  #{board.stations.map(&:path).map(&:size).max}
  * Avg route length:  #{board.stations.map(&:path).map(&:size).avg}
  * Median route length: #{board.stations.map(&:path).map(&:size).median}

  * Min route points:   #{board.stations.map(&:high_value).min}
  * Max route points:   #{board.stations.map(&:high_value).max}
  * Avg route points:   #{board.stations.map(&:high_value).avg}
  * Median route points:  #{board.stations.map(&:high_value).median}

  * Min number of transfers:  #{board.stations.map { |s| board.count_station_path_transfers(s) }.min}
  * Max number of transfers:  #{board.stations.map { |s| board.count_station_path_transfers(s) }.max}
  * Avg number of transfers:  #{board.stations.map { |s| board.count_station_path_transfers(s) }.avg}
  * Median number of transfers: #{board.stations.map { |s| board.count_station_path_transfers(s) }.median}

  * Min transfer points:  #{board.transfers.map(&:value).min}
  * Max transfer points:  #{board.transfers.map(&:value).max}
  * Avg transfer points:  #{board.transfers.map(&:value).avg}
  * Median transfer points: #{board.transfers.map(&:value).median}

  * Min route length to route points:  \#{board.stations.map { |s| ratio(s.path.size, s.high_value) }.min}
  * Max route length to route points:  \#{board.stations.map { |s| ratio(s.path.size, s.high_value) }.max}
  * Avg route length to route points:  \#{board.stations.map { |s| ratio(s.path.size, s.high_value) }.avg}
  * Median route length to route points: \#{board.stations.map { |s| ratio(s.path.size, s.high_value) }.median}

  * Min num transfers to route points:  \#{board.stations
  * Max num transfers to route points:  \#{board.stations
  * Avg num transfers to route points:  \#{board.stations
  * Median num transfers to route points: \#{board.stations

  * Min num transfers to route points:  TODO
  * Max num transfers to route points:  TODO
  * Avg num transfers to route points:  TODO
  * Median num transfers to route points: TODO

  * Min number of station boxes:  #{board.stations.map { |s| s.num_boxes }.min}
  * Max number of station boxes:  #{board.stations.map { |s| s.num_boxes }.max}
  * Avg number of station boxes:  #{board.stations.map { |s| s.num_boxes }.avg}
  * Median number of station boxes: #{board.stations.map { |s| s.num_boxes }.median}

  * Transfer overlap
  * Station boxes
  * Number of each segment length
  EOF
end

class MapGenerator
  class Spec
    def initialize(spec = {})
      defaults = {
        num_routes: 9,
        num_nodes: 78,
        num_transfers: 23,
        total_route_points: 39,
        total_transfer_points: 98,
        route_length: {
          min: 6,
          max: 19,
          median: 11,
        },
        route_points: {
          min: 2,
          max: 7,
          median: 4,
        },
        route_transfers: {
          min: 2,
          max: 7,
          median: 6,
        },
        transfer_points: {
          min: 4,
          max: 6,
          median: 4,
        },
        # TODO: @jbodah 2020-07-12: ratios are critical here; we don't want impossible routes
        station_boxes: {
          min: 2,
          max: 4,
          median: 2,
        }
      }
      @spec = defaults.merge(spec)
    end

    def method_missing(sym, *_)
      @spec.fetch(sym)
    end
  end

  attr_reader :spec

  def initialize(spec)
    @spec = spec
  end

  def generate_map
    # output is a list of stations
    names = %i(red orange pink green yellow purple blue grey dark_geen)
    names = names[0..spec.num_routes]

    capacity_bucket = spec.num_nodes
    even_round_down = spec.num_nodes / names.size
    capacity_bucket -= names.size * even_round_down
    builders = names.map do |n|
      {route: {name: n}, capacity: even_round_down}
    end

    redistribute_capacity_randomly = -> {
      case [true, false].sample
      when true
        remove_from = builders[(0..builders.size-1).to_a.sample]
        val = (1..5).to_a.sample
        new_cap = remove_from[:capacity] - val
        next unless (spec.route_length[:min]..spec.route_length[:max]).include?(new_cap)
        puts builders.inspect
        puts remove_from
        remove_from[:capacity] = new_cap
        puts new_cap
        puts builders.inspect
        capacity_bucket += val
      else
        add_to = builders[(0..builders.size-1).to_a.sample]
        val = (1..5).to_a.sample
        new_cap = add_to[:capacity] + val
        next unless (spec.route_length[:min]..spec.route_length[:max]).include?(new_cap)
        next unless capacity_bucket - val >= 0
        add_to[:capacity] = new_cap
        capacity_bucket -= val
      end
    }

    timeout_at = Time.now + 3
    redistribute_capacity_randomly.call until Time.now == timeout_at

    capacity_meets_spec = -> {
      caps = builders.map { |b| b[:capacity] }
      puts({median: caps.median, min: caps.min, max: caps.max})
      caps.median == spec.route_length[:median] &&
        caps.min == spec.route_length[:min] &&
        caps.max == spec.route_length[:max]
    }

    redistribute_capacity_randomly.call until capacity_meets_spec.call

    puts builders
  end
end

# MapGenerator.new(MapGenerator::Spec.new).generate_map

# analyze $map

# test_player FirstAvailableStationPlayer
# test_player RandomPlayer
# test_player RandomButMaximizeTransfersPlayer
# test_player GreedyIfCompletePlayer

# TODO: @jbodah 2020-07-12: report succes by route
test_player MaxFitPlayer, $map
