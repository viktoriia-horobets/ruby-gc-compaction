require 'ostruct'
require 'csv'
require 'benchmark'

RUNS          = (ENV['RUNS'] || 5).to_i          
N_OBJECTS     = (ENV['N_OBJECTS'] || 300_000).to_i
KEEP_EVERY    = (ENV['KEEP_EVERY'] || 3).to_i      
DO_COMPACT    = ENV['DO_COMPACT'] == '1'           
CSV_OUT       = ENV['CSV_OUT'] || (DO_COMPACT ? 'data/results_manual_compact.csv' : 'data/results_no_compact.csv')

GC.auto_compact = false if GC.respond_to?(:auto_compact=)

def stat_hash(label)
  s = GC.stat
  {
    label: label,
    heap_allocated_pages: s[:heap_allocated_pages],
    heap_available_slots: s[:heap_available_slots],
    heap_live_slots:      s[:heap_live_slots],
    heap_free_slots:      s[:heap_free_slots],
    minor_gc_count:       s[:minor_gc_count],
    major_gc_count:       s[:major_gc_count],
  }
end

def build_fragmented_heap(n_objects:, keep_every:)
  keep = []
  n_objects.times do |i|
    case i % 3
    when 0
      obj = "x" * (5 + (i % 10))
    when 1
      obj = Array.new(5 + (i % 20)) { i }
    else
      obj = OpenStruct.new(id: i, name: "obj-#{i}", payload: "p" * (i % 50))
    end
    keep << obj if (i % keep_every == 0)
  end
  keep
end

def full_major_gc
  GC.start(full_mark: true, immediate_sweep: true)
end

rows = []
RUNS.times do |run_idx|
  before_all = stat_hash("before_all")

  t_alloc = Benchmark.realtime do
    @keep_refs = build_fragmented_heap(n_objects: N_OBJECTS, keep_every: KEEP_EVERY)
  end

  t_major_before = Benchmark.realtime { full_major_gc }

  before_compact = stat_hash("before_compact")

  t_compact = 0.0
  if DO_COMPACT && GC.respond_to?(:compact)
    t_compact = Benchmark.realtime { GC.compact }
  end

  t_major_after = Benchmark.realtime { full_major_gc }

  after_compact = stat_hash("after_compact")

  rows << {
    run: run_idx + 1,
    do_compact: DO_COMPACT ? 1 : 0,
    n_objects: N_OBJECTS,
    keep_every: KEEP_EVERY,
    alloc_time_s: t_alloc.round(6),
    major_before_s: t_major_before.round(6),
    compact_time_s: t_compact.round(6),
    major_after_s: t_major_after.round(6),

    before_heap_pages: before_compact[:heap_allocated_pages],
    before_free_slots: before_compact[:heap_free_slots],
    before_live_slots: before_compact[:heap_live_slots],

    after_heap_pages:  after_compact[:heap_allocated_pages],
    after_free_slots:  after_compact[:heap_free_slots],
    after_live_slots:  after_compact[:heap_live_slots],
  }
end

need_header = !File.exist?(CSV_OUT)
CSV.open(CSV_OUT, need_header ? 'w' : 'a') do |csv|
  if need_header
    csv << rows.first.keys
  end
  rows.each { |r| csv << r.values }
end

puts "Saved: #{CSV_OUT}"
