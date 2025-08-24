# scripts/compaction_experiment.rb
require 'ostruct'
require 'csv'
require 'benchmark'

RUNS           = (ENV['RUNS'] || 5).to_i

N_OBJECTS      = (ENV['N_OBJECTS'] || 1_200_000).to_i
KEEP_EVERY     = (ENV['KEEP_EVERY'] || 5).to_i

DO_COMPACT     = ENV['DO_COMPACT'] == '1'   # manual GC.compact
AUTO_MODE      = ENV['AUTO_MODE']  == '1'   # auto-compact mode
DOUBLE_COMPACT = ENV['DOUBLE_COMPACT'] == '1'

CSV_OUT        = ENV['CSV_OUT'] || (DO_COMPACT ? 'data/results_manual_compact.csv' :
                                   (AUTO_MODE ? 'data/results_auto_compact.csv' : 'data/results_no_compact.csv'))

CHURN              = (ENV['CHURN'] || '1') == '1'
CHURN_PASSES       = (ENV['CHURN_PASSES'] || 4).to_i     
CHURN_BATCHES      = (ENV['CHURN_BATCHES'] || 12).to_i   
CHURN_ARR_SIZE_BIG = (ENV['CHURN_ARR_SIZE_BIG'] || 120_000).to_i
CHURN_ARR_SIZE_SML = (ENV['CHURN_ARR_SIZE_SML'] || 8_000).to_i

if GC.respond_to?(:auto_compact=)
  if AUTO_MODE
    GC.auto_compact = true
  else
    GC.auto_compact = false
  end
end

def stat_hash(label)
  s = GC.stat
  {
    label:                  label,
    heap_allocated_pages:   s[:heap_allocated_pages],
    heap_available_slots:   s[:heap_available_slots],
    heap_live_slots:        s[:heap_live_slots],
    heap_free_slots:        s[:heap_free_slots],
    minor_gc_count:         s[:minor_gc_count],
    major_gc_count:         s[:major_gc_count],
  }
end

def build_fragmented_heap(n_objects:, keep_every:)
  keep = []
  n_objects.times do |i|
    case i % 4
    when 0
      obj = "x" * (32 + (i % 400))                         
    when 1
      obj = Array.new(8 + (i % 200)) { i * 3 }            
    when 2
      hash = {}
      (i % 40).times { |k| hash["k#{k}"] = "v" * (k % 60) }
      obj = hash
    else
      obj = OpenStruct.new(id: i, name: "obj-#{i}", blob: "p" * (i % 800))
    end
    keep << obj if (i % keep_every == 0)                   
  end
  keep
end

def full_major_gc
  GC.start(full_mark: true, immediate_sweep: true)
end


def churn_wave(batches:, big:, small:)
  batches.times do |b|
    big_arr  = Array.new(big)  { "X" * (48 + (b % 128)) }  
    small_arr= Array.new(small){ "y" * (8  + (b % 32))  }  
  end
end

def induce_strong_fragmentation(n_objects:, keep_every:, passes:, batches:, big:, small:)
  keep_refs = []
  passes.times do
    keep_refs.concat(build_fragmented_heap(n_objects: n_objects / passes, keep_every: keep_every))
    churn_wave(batches: batches, big: big, small: small)
    full_major_gc
  end
  keep_refs
end

rows = []
RUNS.times do |run_idx|
  t_alloc = Benchmark.realtime do
    if CHURN
      @keep_refs = induce_strong_fragmentation(
        n_objects: N_OBJECTS,
        keep_every: KEEP_EVERY,
        passes: CHURN_PASSES,
        batches: CHURN_BATCHES,
        big: CHURN_ARR_SIZE_BIG,
        small: CHURN_ARR_SIZE_SML
      )
    else
      @keep_refs = build_fragmented_heap(n_objects: N_OBJECTS, keep_every: KEEP_EVERY)
    end
  end

  before_compact = stat_hash("before_compact") if AUTO_MODE

  t_major_before = Benchmark.realtime { full_major_gc }

  before_compact ||= stat_hash("before_compact")

  t_compact = 0.0
  if DO_COMPACT && GC.respond_to?(:compact)
    t_compact += Benchmark.realtime { GC.compact }
    if DOUBLE_COMPACT
      full_major_gc
      t_compact += Benchmark.realtime { GC.compact }
    end
  end

  t_major_after = Benchmark.realtime { full_major_gc }
  after_compact = stat_hash("after_compact")

  rows << {
    run:               run_idx + 1,
    do_compact:        DO_COMPACT ? 1 : 0,
    n_objects:         N_OBJECTS,
    keep_every:        KEEP_EVERY,
    alloc_time_s:      t_alloc.round(6),
    major_before_s:    t_major_before.round(6),
    compact_time_s:    t_compact.round(6),
    major_after_s:     t_major_after.round(6),

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
  csv << rows.first.keys if need_header
  rows.each { |r| csv << r.values }
end

puts "Saved: #{CSV_OUT}"
