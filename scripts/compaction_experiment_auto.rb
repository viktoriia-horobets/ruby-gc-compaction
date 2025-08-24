# scripts/compaction_experiment_auto.rb

GC.auto_compact = true if GC.respond_to?(:auto_compact=)

ENV['DO_COMPACT'] = '0'   
ENV['AUTO_MODE']  = '1'   

load File.join(__dir__, 'compaction_experiment.rb')
