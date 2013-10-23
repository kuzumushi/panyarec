# -*- coding: utf-8 -*-
module Recorder
  # 複数の区間[a,b)を扱うクラス
  class RangeTable
    def initialize
      @table = Hash.new
      @table.default = 0
    end

    # Rangeオブジェクトを追加
    def add(range)
      raise "ranbe must be begin < end." if range.begin >= range.end
      @table[range.begin] += 1
      @table[range.end]   -= 1
      @last_added = range
    end

    # 最後に追加されたRangeオブジェクトを削除
    def remove_last
      raise "no range has added yet." unless @last_added
      @table[@last_added.begin] -= 1
      @table[@last_added.end]   += 1
    end
=begin
    # 最大重複数を返す
    # ・時間計算量はO(Rangeオブジェクトの数)
    def get_max_overlap(range=nil)
      max_overlap = 0
      @table.sort.inject(0) do |overlap, point|
        value, diff = point
        if !range || (range.begin < value && value < range.end)
          max_overlap = [max_overlap, overlap].max
        end
        overlap + diff
      end
      return max_overlap
    end

=end
    # 最大重複数を返す
    # ・時間計算量はO(Rangeオブジェクトの数)
    def get_max_overlap(target_range=nil)
      ranges = Array.new
      now_overlap = 0
      @table.sort.each_cons(2) do |p1, p2|
        now_overlap += p1[1]
        ranges.push(:range => p1[0]..p2[0], :overlap => now_overlap)
      end
      max_overlap_range = ranges.select{|r| !target_range || (r[:range].begin < target_range.end && target_range.begin < r[:range].end)}.max{|r1, r2| r1[:overlap] <=> r2[:overlap]}
      if max_overlap_range
        return max_overlap_range[:overlap]
      else
        return 0
      end
    end

    # from以上の範囲で、長さがduration以上、超複数がoverlap未満の区間(Range)の内、左端の最小値を返す。
    # ・分割単位は全ての材料区間の始点/終点。
    # ・有限値でない場合、右端は適当に大きな値となる。
    # ・時間計算量はO(Rangeオブジェクトの数)
    def next_range_begin(from, duration, overlap)
      return from unless tail
      end_of_range = [tail, from].max
      ranges = get_under(overlap) << (end_of_range..(end_of_range + duration))
      range_joint(ranges).each do |range|
        begin_of_range = [range.begin, from].max
        if range.end - begin_of_range >= duration
          return begin_of_range
        end
      end
      raise "duration not found (strange occasion)."
    end

    # 重複数がoverlap_number未満になる区間全てからならる配列を返す
    # ・右端の最大値はRangeオブジェクトの端の最大値であることに注意。
    # ・時間計算量はO(Rangeオブジェクトの数)
    def get_under(overlap)
      ranges = Array.new
      now_overlap = 0
      @table.sort.each_cons(2) do |p1, p2|
        now_overlap += p1[1]
        ranges.push(p1[0]..p2[0]) if now_overlap < overlap
      end
      return ranges
    end

    # 区間の配列を受け取り、重複した区間を結合した配列を返す。
    # ・状態に依存しない純粋関数。
    # ・連続した区間も結合する。例) [ 0..5, 5..10] => [ 0..10 ]
    # ・あらかじめソートしておく必要はない。
    def range_joint(range_array)
      return range_array.sort{|r1,r2| r1.begin <=> r2.begin}.inject([]) do |jointed, range|
        if jointed[-1] && jointed[-1].end >= range.begin
          jointed[-1] = jointed[-1].begin..([range.end, jointed[-1].end].max)
        else
          jointed.push(range)
        end
        jointed
      end
    end

    # 始点/終点の値の最大値を返す
    # 区間が0個の場合はnilを返す。
    def tail
      return @table.sort.map{|p| p[0]}.max
    end
  end
end